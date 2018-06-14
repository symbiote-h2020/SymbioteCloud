#!/bin/bash

symbioteCloudName="SymbioteCloud"

cloudConfigServiceVersion=2.0.0
eurekaServiceVersion=2.0.0
zipkinServiceVersion=2.0.0
authenticationAuthorizationManagerVersion=3.1.1
registrationHandlerVersion=2.0.0
resourceAccessProxyVersion=2.0.1

symbIoTeSecurityVersion=25.6.0

# TODO: Set to true for docker deployment
docker=true

# function for downloading on jar
# arguments: componentName, version
download_jar () {
    echo "Downloading $1, version $2"
    cd $1
    wget https://jitpack.io/com/github/symbiote-h2020/$1/$2/$1-$2-run.jar
    cd ..
}

jar_download() {
    echo "Downloading jars"

    # Cloud Config server
    mkdir CloudConfigService
    download_jar "CloudConfigService" $cloudConfigServiceVersion 

    # Eureka service
    mkdir EurekaService
    download_jar "EurekaService" $eurekaServiceVersion 

    # Zipkin service
    mkdir ZipkinService
    download_jar "ZipkinService" $zipkinServiceVersion 

    # AAM
    mkdir AuthenticationAuthorizationManager
    download_jar "AuthenticationAuthorizationManager" $authenticationAuthorizationManagerVersion 
    wget https://jitpack.io/com/github/symbiote-h2020/SymbIoTeSecurity/$symbIoTeSecurityVersion/SymbIoTeSecurity-$symbIoTeSecurityVersion-helper.jar -O AuthenticationAuthorizationManager/SymbIoTeSecurity-$symbIoTeSecurityVersion-helper.jar
    wget https://www.bouncycastle.org/download/bcprov-jdk15on-159.jar -O AuthenticationAuthorizationManager/bcprov-jdk15on-159.jar

    # RH
    mkdir RegistrationHandler
    download_jar "RegistrationHandler" $registrationHandlerVersion 

    # RAP
    mkdir ResourceAccessProxy
    download_jar "ResourceAccessProxy" $resourceAccessProxyVersion

    download_cloudConfig
}

# function for downloading on jar
# arguments: componentName
compile_jar() {
    cd SymbioteCloud/$1
    echo "Compiling $1"
    gradle clean assemble --refresh-dependencies
    cd ../..
}

copy_jar() {
    echo "Copying jar $1"
    mkdir $1
    cp SymbioteCloud/$1/build/libs/*-run.jar $1/

}

src_download() {
    echo "Downloading sources from github"

    # download from github
    git clone --recursive https://github.com/symbiote-h2020/SymbioteCloud.git

    # compile components
    compile_jar AuthenticationAuthorizationManager
    compile_jar CloudConfigService
    compile_jar EurekaService
    compile_jar RegistrationHandler
    compile_jar ResourceAccessProxy
    compile_jar ZipkinService

    # move jars
    copy_jar AuthenticationAuthorizationManager
    copy_jar CloudConfigService
    copy_jar EurekaService
    copy_jar RegistrationHandler
    copy_jar ResourceAccessProxy
    copy_jar ZipkinService
    wget https://jitpack.io/com/github/symbiote-h2020/SymbIoTeSecurity/$symbIoTeSecurityVersion/SymbIoTeSecurity-$symbIoTeSecurityVersion-helper.jar -O AuthenticationAuthorizationManager/SymbIoTeSecurity-$symbIoTeSecurityVersion-helper.jar
    wget https://www.bouncycastle.org/download/bcprov-jdk15on-159.jar -O AuthenticationAuthorizationManager/bcprov-jdk15on-159.jar

    download_cloudConfig
}

clear_downloads() {
    echo "Clearing downloads"
    rm -rf AuthenticationAuthorizationManager CloudConfigProperties CloudConfigService EurekaService RegistrationHandler ResourceAccessProxy ZipkinService nginx.conf SymbioteCloud
}

clear_keystores() {
    echo "Clearing keystores"
    rm -f AuthenticationAuthorizationManager/*.p12 RegistrationHandler/*.jks ResourceAccessProxy/*.jks
}

# Cloud Config properties
# git colne repo
download_cloudConfig() {
    echo "Downloading CloudConfigProperties"

    if [ "$docker" = true ]; then
      git clone --branch master --single-branch --depth 1 https://github.com/symbiote-h2020/CloudConfigProperties.git
    else
      git clone https://github.com/symbiote-h2020/CloudConfigProperties.git
    fi
}

unzip_configuration() {
    echo "Unzipping configuration"
    # unzip configuration
    unzip -o configuration.zip
}

configure() {
    echo "Configuring platform"
    echo "symbIoTeSecurityVersion=$symbIoTeSecurityVersion"
    echo "JAVA_HTTP_PROXY=$JAVA_HTTP_PROXY"
    echo "JAVA_HTTPS_PROXY=$JAVA_HTTPS_PROXY"
    echo "JAVA_SOCKS_PROXY=$JAVA_SOCKS_PROXY"
    echo "JAVA_NON_PROXY_HOSTS=$JAVA_NON_PROXY_HOSTS"

    javaFlags="$JAVA_HTTP_PROXY $JAVA_HTTPS_PROXY $JAVA_SOCKS_PROXY $JAVA_NON_PROXY_HOSTS"
    unzip_configuration

    if [ -f CloudConfigService/bootstrap.properties ] ; then
        rm CloudConfigService/bootstrap.properties
    fi
    touch CloudConfigService/bootstrap.properties
    echo "spring.cloud.config.server.git.uri=file://$PWD/CloudConfigProperties" >> CloudConfigService/bootstrap.properties
    echo "server.port=8888" >> CloudConfigService/bootstrap.properties

    # AAM security - keystore generation
    cd AuthenticationAuthorizationManager
    java $JAVA_HTTP_PROXY $javaFlags -cp SymbIoTeSecurity-$symbIoTeSecurityVersion-helper.jar:bcprov-jdk15on-159.jar eu.h2020.symbiote.security.helpers.ServiceAAMCertificateKeyStoreFactory cert.properties
    cd ..
}

configure_debug() {
    echo "Enabling DEBUG mode"
    configure

    echo "" >> CloudConfigProperties/application.properties
    echo "logging.level.eu.h2020.symbiote=DEBUG" >> CloudConfigProperties/application.properties
}

function startService {
  echo "Starting $1"
  
  javaFlags="$JAVA_HTTP_PROXY $JAVA_HTTPS_PROXY $JAVA_NON_PROXY_HOSTS"

  # Find the name of the jar
  cd $1
  jar=$(ls *run.jar)
  cd ..

  # Make a new screen and give it a name
  screen -X screen -t $1

  # Make screen cd to the service and start it
  # then cd back so the working dir stays in the root
  screen -X chdir $1
  if [ $2 ]
  then 
    screen -X exec java $javaFlags -DSPRING_BOOT_WAIT_FOR_SERVICES=$2 -jar $jar
  else
    screen -X exec java $javaFlags -jar $jar
  fi

  screen -X chdir ..
}

startScreen() {
    echo "Starting screen"
    screen -d -m -S $symbioteCloudName
    sleep 2

    screen -X caption always "%t"


    startService CloudConfigService
    startService EurekaService
    startService ZipkinService
    startService AuthenticationAuthorizationManager
    startService RegistrationHandler localhost:8080
    startService ResourceAccessProxy localhost:8080
}

stopScreen() {
    echo "Stopping screen"

    # get screen pid
    SCREEN_PID=`screen -ls | grep $symbioteCloudName | awk '/\.\w*\t/ {print strtonum($1)}'`
    # kill all proceses that has parent screen pid 
    for i in `ps -xao pid,ppid,command | grep $SCREEN_PID | grep java | awk '{ print $1 }'`; do kill -9 $i; done
    # kill screen
    screen -X -S $symbioteCloudName quit
}

install() {
    echo "Installing..."
    jar_download
    configure
}

uninstall() {
    echo "Unistalling"
    clear_downloads
}

restart() {
    echo "Restarting"
    stop
    sleep 2
    start
}

stop() {
    echo "Stopping.."
    stopScreen
    echo "Stopped components"
}

configure_and_start() {
    echo "Configure and start the components"
    screen -wipe
    ls AuthenticationAuthorizationManager/*.p12
    isConfigured=$?

    if [ $isConfigured -gt 0 ]; then
      echo "The deployment is not configured"
      configure
    fi
    start
}

start() {
    echo "Components are starting..."
    startScreen
    echo "For watching components starting run: screen -x"
    if [ "$docker" = true ]; then
      touch dummy_file
      tail -f dummy_file
    fi
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    restart
    ;;
  install)
    install
    ;;
  uninstall)
    uninstall
    ;;
 jar_download)
   jar_download
   ;;
 src_download)
   src_download
   ;;
 configure)
   configure
   ;;
 configure_debug)
   configure_debug
   ;;
 configure_and_start)
   configure_and_start
   ;;
 clear_keystores)
   clear_keystores
   ;;
  *)
    echo "Usage: $0 {command}" 
    echo "COMMANDS:"
    echo "  start - Starts SymbIoTe Cloud"
    echo "  stop - Stops SymbIoTe Cloud"
    echo "  restart - Restarts SymbIoTe Cloud"
    echo "  install - Installs SymbIoTe Cloud (download jars and configure in current dir)"
    echo "  uninstall - Uninstalls SymbIoTe Cloud (remove installation in current dir)"
    echo "  jar_download - Download SymbIoTe Cloud components in jars"
    echo "  src_download - Download SymbIoTe Cloud components from github repositories and create jars"
    echo "  configure - Configure SymbIoTe Cloud components from configuration.zip"
    echo "  configure_debug - Configure SymbIoTe Cloud components from configuration.zip"
    echo "  configure_and_start - Configure SymbIoTe Cloud components from configuration.zip if it is not configured and start SymbIoTe Cloud"
    echo "  clear_keystores - Deletes keystores in SymbIoTe Cloud components. After that run configure command again."
esac