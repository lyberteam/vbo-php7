# PHP7-FPM
FROM php:fpm

MAINTAINER Vendor="lyberteam" Description="This is a new php-fpm image(version for now 7.0.9)"

LABEL version="1.0"

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng12-dev \
        libmcrypt-dev \
        libicu-dev \
        libpq-dev \
        libbz2-dev \
        php-pear \
        curl \
        git \
        unzip \
        mc \
        vim \
        wget \
#        libevent-dev \
        librabbitmq-dev \
    && docker-php-ext-install iconv \
    && docker-php-ext-install mcrypt \
    && docker-php-ext-install zip \
    && docker-php-ext-install bz2 \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install intl \
    && docker-php-ext-install pgsql pdo pdo_pgsql \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install pdo_sqlite \
    && docker-php-ext-install mysqli \
    && docker-php-ext-install bcmath \
    && docker-php-ext-install opcache \
    && docker-php-ext-configure gd \
        --enable-gd-native-ttf \
        --with-freetype-dir=/usr/include/freetype2 \
        --with-png-dir=/usr/include \
        --with-jpeg-dir=/usr/include \
    && docker-php-ext-install gd \
    && docker-php-ext-install mbstring \
    && docker-php-ext-enable opcache gd

# Change TimeZone
RUN echo "Europe/Kiev" > /etc/timezone

# install composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

RUN printf "\n" | pecl install apcu-beta && echo extension=apcu.so > /usr/local/etc/php/conf.d/10-apcu.ini
RUN printf "\n" | pecl install apcu_bc-beta && echo extension=apc.so > /usr/local/etc/php/conf.d/apc.ini

RUN printf "\n" | pecl install channel://pecl.php.net/amqp-1.7.0alpha2 && echo extension=amqp.so > /usr/local/etc/php/conf.d/amqp.ini

RUN pecl install channel://pecl.php.net/ev-1.0.0RC3 && echo extension=ev.so > /usr/local/etc/php/conf.d/ev.ini

# compile redis for php-7
RUN cd /etc && git clone --depth=1 -b php7 https://github.com/phpredis/phpredis.git \
#    && git checkout php7 \
    && cd /etc/phpredis \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && touch /usr/local/etc/php/conf.d/ext-redis.ini \
    && echo 'extension=redis.so' >> /usr/local/etc/php/conf.d/ext-redis.ini

RUN ln -sf /dev/stdout /var/log/access.log && ln -sf /dev/stderr /var/log/error.log

COPY php.ini /usr/local/etc/php/

RUN /bin/bash -c 'rm -f /usr/local/etc/php-fpm.d/www.conf.default'
ADD symfony.pool.conf /usr/local/etc/php-fpm.d/
RUN rm -f /usr/local/etc/php-fpm.d/www.conf

RUN usermod -u 1000 www-data

CMD ["php-fpm"]

EXPOSE 9000

RUN  dpkg-reconfigure -f noninteractive tzdata

RUN cd /tmp
RUN wget http://xdebug.org/files/xdebug-2.4.1.tgz

RUN tar -xvzf xdebug-2.4.1.tgz
RUN cd xdebug-2.4.1

#RUN /usr/local/bin/phpize
RUN /usr/bin/phpize
RUN ./configure --enable-xdebug --with-php-config=/usr/local/bin/php-config \
    && make \
    && make test

RUN cp modules/xdebug.so /usr/local/lib/php/extensions/no-debug-non-zts-20151012/

RUN rm -R /tmp/*