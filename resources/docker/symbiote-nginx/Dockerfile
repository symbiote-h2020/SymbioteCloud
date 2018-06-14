FROM nginx:alpine

WORKDIR /home

COPY ./nginx.sh nginx.sh

RUN chmod 744 nginx.sh 

EXPOSE 443 8102

CMD ["sh", "./nginx.sh"]
