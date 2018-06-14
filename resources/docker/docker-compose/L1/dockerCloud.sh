#!/bin/bash

install() {
    cd symbiote-cloud
    docker build -t symbiote-cloud .
    cd ..

    cd symbiote-nginx
    docker build -t symbiote-nginx .
    cd ..
}

uninstall() {
    docker volume rm $(docker volume ls -f name=symbiote-vol --format "{{.Name}}")
    docker rmi symbiote-cloud symbiote-nginx
}

start() {
    docker-compose -f docker-compose.yml -f docker-compose-prod.yml up -d
    printStartMessage
}

start-ngrok() {
    docker-compose -f docker-compose.yml -f docker-compose-ngrok.yml up -d
    printStartMessage
}

printStartMessage() {
    echo " "
    echo "Starting all components can take several minutes."
    echo "With command './dockerCloud.sh wait {Interworking Service URL}' you can wait for all components to start"
    echo " "
    echo "With command 'docker-compose logs -f' you can watch starting containers."
    echo "After all containers are started you can ssh to symbiote-cloud container with './dockerCloud.sh cloud-shell'"
    echo "In the symbiote-cloud container you can watch components startup with 'screen -x'"
}

stop() {
    docker-compose -f docker-compose.yml -f docker-compose-prod.yml down
}

ngrok-machine() {
    ngrok http --bind-tls "true" $(docker-machine ip default):8102
}

ngrok-local() {
    ngrok http --bind-tls "true" 8102
}

cloud-shell() {
    docker exec -it symbiote-cloud /bin/sh
}

export-images() {
    echo "Exporting images"
    rm -rf images
    mkdir images
    echo "Exporting rabbitmq"
    docker save -o images/rabbitmq.tar rabbitmq:3-alpine
    echo "Exporting mongo"
    docker save -o images/mongo.tar mongo:3.6
    echo "Exporting symbiote-cloud"
    docker save -o images/symbiote-cloud.tar symbiote-cloud
    echo "Exporting symbiote-nginx"
    docker save -o images/symbiote-nginx.tar symbiote-nginx
}

import-images() {
    echo "Importing images"
    echo "Importing rabbitmq"
    docker load -i images/rabbitmq.tar
    echo "Importing mongo"
    docker load -i images/mongo.tar
    echo "Importing symbiote-cloud"
    docker load -i images/symbiote-cloud.tar
    echo "Importing symbiote-nginx"
    docker load -i images/symbiote-nginx.tar
}

check() {
    if [ -z "$1" ]; then
        echo "Can not chack without platform Interworking Services URL!"
        exit 1
    fi

    nginxUrl=$1

    checkUrl $nginxUrl 404 "Nginx"
    checkUrl "$nginxUrl/paam/get_available_aams" 200 "AAM"
    checkUrl "$nginxUrl/rh/resources" 200 "RH"
    checkUrl "$nginxUrl/rap/Sensors('x')" 404 "RAP"
}

checkUrl() {
    result=$(curl -o /dev/null --silent --write-out '%{http_code}' $1)
    if [ "$2" == "$result" ]; then
        echo "$3 OK"
    elif [ "000" == "$result" ]; then
        echo "$3 NOT RUNNING"
    elif [ "502" == "$result" ]; then
        echo "$3 NOT RUNNING"
    else
        echo "$3 ERROR"
        echo "  Response code:"
        echo "    expecting: $2"
        echo "    actual: $result"
    fi
}

wait() {
    if [ -z "$1" ]; then
        echo "Can not chack without platform Interworking Services URL!"
        exit 1
    fi

    nginxUrl=$1
    waitForUrl $nginxUrl 404 "Nginx"
    waitForUrl "$nginxUrl/paam/get_available_aams" 200 "AAM"
    waitForUrl "$nginxUrl/rh/resources" 200 "RH"
    waitForUrl "$nginxUrl/rap/Sensors('x')" 404 "RAP"
}

waitForUrl() {
    echo "Waiting for $3"
    until [ $(curl -o /dev/null --silent --write-out '%{http_code}' $1) == "$2" ]; do
        printf '.'
        sleep 2
    done
    echo " STARTED"
}

case "$1" in
  start)
    start
    ;;
  start-ngrok)
    start-ngrok
    ;;
  stop)
    stop
    ;;
  install)
    install
    ;;
  uninstall)
    uninstall
    ;;
  ngrok-machine)
    ngrok-machine
    ;;
  ngrok-local)
    ngrok-local
    ;;
  cloud-shell)
    cloud-shell
    ;;
  export-images)
    export-images
    ;;
  import-images)
    import-images
    ;;
  check)
    check $2
    ;;
  wait)
    wait $2
    ;;
  *)
    echo "Usage: $0 {command}"
    echo "COMMANDS:"
    echo "  install - Installs SymbIoTe Cloud (create images)"
    echo "  uninstall - Uninstalls SymbIoTe Cloud (remove containers and images)"
    echo "  start - Start SymbIoTe Cloud Production Environment in Docker"
    echo "  start-ngrok - Start SymbIoTe Cloud ngrok Environment in Docker"
    echo "  stop - Stops SymbIoTe Cloud in Docker"
    echo "  ngrok-machine - Start ngrok tunnel to docker-machine default"
    echo "  ngrok-local - Start ngrok tunnel to localhost"
    echo "  cloud-shell - Shell into symbiote-cloud container. To watch starting components run 'screen -x'"
    echo "  export-images - Export imaged into files"
    echo "  import-images - Import images from files"
    echo "  check {Interworking Service URL} - Checks if all components are running"
    echo "  wait {Interworking Service URL} - Wait until all components are running"
esac