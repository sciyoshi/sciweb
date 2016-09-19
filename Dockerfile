FROM nginx

ADD nginx/nginx.conf /etc/nginx/nginx.conf

VOLUME /var/www
