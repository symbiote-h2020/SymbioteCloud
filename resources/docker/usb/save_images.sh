#!/bin/sh

echo "Saving images"

rm -rf images
mkdir images

echo "Saving rabbitmq"
docker save -o images/rabbitmq.tar rabbitmq:3-alpine

echo "Saving mongo"
docker save -o images/mongo.tar mongo:3.6

echo "Saving symbiote-cloudconfig"
docker save -o images/symbiote-cloudconfig.tar symbioteh2020/symbiote-cloudconfig:latest

echo "Saving symbiote-aam"
docker save -o images/symbiote-aam.tar symbioteh2020/symbiote-aam:latest

echo "Saving symbiote-eureka"
docker save -o images/symbiote-eureka.tar symbioteh2020/symbiote-eureka:latest

echo "Saving symbiote-rap"
docker save -o images/symbiote-rap.tar symbioteh2020/symbiote-rap:latest

echo "Saving symbiote-rh"
docker save -o images/symbiote-rh.tar symbioteh2020/symbiote-rh:latest

echo "Saving symbiote-monitoring"
docker save -o images/symbiote-monitoring.tar symbioteh2020/symbiote-monitoring:latest

echo "Saving symbiote-rappluginexample"
docker save -o images/symbiote-rappluginexample.tar symbioteh2020/symbiote-rappluginexample:latest

echo "Saving symbiote-nginx"
docker save -o images/symbiote-nginx.tar symbioteh2020/symbiote-nginx:latest
