FROM php:7.0.8-apache

RUN apt-get update && apt-get install -y \
        bzip2 \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg-dev \
        libmcrypt-dev \
        libmemcached-dev \
        libpng12-dev \
        libpq-dev \
        libxml2-dev \
        git \
        unzip \
        && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
        && docker-php-ext-install gd exif intl mbstring mcrypt mysqli opcache pdo_mysql pdo_pgsql pgsql zip

RUN { \
                echo 'opcache.memory_consumption=128'; \
                echo 'opcache.interned_strings_buffer=8'; \
                echo 'opcache.max_accelerated_files=4000'; \
                echo 'opcache.revalidate_freq=60'; \
                echo 'opcache.fast_shutdown=1'; \
                echo 'opcache.enable_cli=1'; \
        } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN cd /tmp && \
    git clone https://github.com/php-memcached-dev/php-memcached.git && \
    cd php-memcached && \
    git checkout php7 && \
    phpize && \
    ./configure --disable-memached-sasl && \
    make && make install && \
    echo "extension=memcached.so" > /usr/local/etc/php/conf.d/20-memcached.ini

RUN set -ex \
        && pecl install APCu \
        && pecl install redis \
        && docker-php-ext-enable apcu redis

RUN a2enmod rewrite

ENV OWNCLOUD_VERSION 9.0.3
VOLUME /var/www/html

RUN curl -fsSL -o owncloud.tar.bz2 \
		"https://download.owncloud.org/community/owncloud-${OWNCLOUD_VERSION}.tar.bz2" \
	&& curl -fsSL -o owncloud.tar.bz2.asc \
		"https://download.owncloud.org/community/owncloud-${OWNCLOUD_VERSION}.tar.bz2.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys E3036906AD9F30807351FAC32D5D5E97F6978A26 \
	&& gpg --batch --verify owncloud.tar.bz2.asc owncloud.tar.bz2 \
	&& rm -r "$GNUPGHOME" owncloud.tar.bz2.asc \
	&& tar -xjf owncloud.tar.bz2 -C /usr/src/ \
	&& rm owncloud.tar.bz2

COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]

