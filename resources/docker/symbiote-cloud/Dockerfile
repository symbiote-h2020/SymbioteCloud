FROM openjdk:8-jre-alpine

WORKDIR /home

RUN apk --no-cache add \
	screen \
	git \
	unzip \
	wget \
	bash

COPY ./symbioteCloud.sh script.sh

RUN chmod 777 script.sh \
	&& sh ./script.sh jar_download

EXPOSE 8001 8080 8103

CMD ["sh", "./script.sh", "configure_and_start"]