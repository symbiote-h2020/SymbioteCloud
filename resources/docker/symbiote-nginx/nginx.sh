unzip configuration.zip

NGINX_CONF_FILE=nginx-$SYMBIOTE_ENV.conf
mv $NGINX_CONF_FILE /etc/nginx/nginx.conf

nginx -g 'daemon off;'