FROM php:7.2-fpm-alpine

ARG LEAN_VERSION=2.1.4

WORKDIR /var/www/html

# Install dependencies
RUN apk update && apk add --no-cache \
    mysql-client \
    freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev \
    icu-libs \
    jpegoptim optipng pngquant gifsicle \
    supervisor \
    apache2 \
    apache2-ctl \
    apache2-proxy \
    nodejs \
    npm

# Installing extensions
RUN docker-php-ext-install mysqli pdo_mysql mbstring exif pcntl pdo bcmath
RUN docker-php-ext-configure gd --with-gd --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/
RUN docker-php-ext-install gd

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN curl -LJO https://github.com/pedromacarmo/leantime/archive/master.zip && \
    tar -zxvf master.zip --strip-components 1 && \
    rm master.zip

RUN chown www-data -R .

COPY ./start.sh /start.sh
RUN chmod +x /start.sh

COPY config/custom.ini /usr/local/etc/php/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY config/app.conf  /etc/apache2/conf.d/app.conf

# copy thins
#COPY ./data /var/www/test

RUN sed -i '/LoadModule rewrite_module/s/^#//g' /etc/apache2/httpd.conf && \
    sed -i 's#AllowOverride [Nn]one#AllowOverride All#' /etc/apache2/httpd.conf && \
    sed -i '$iLoadModule proxy_module modules/mod_proxy.so' /etc/apache2/httpd.conf

# Expose port 9000 and start php-fpm server
ENTRYPOINT ["/start.sh"]
EXPOSE 80
