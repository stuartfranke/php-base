FROM php:7.3.20-fpm-alpine3.12

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_PACKAGIST_REPO_URL "https://packagist.co.za"
ENV USER_DIRECTORY "/root"
ENV NGINX_GROUP "www-data"
ENV NGINX_USER "www-data"
ENV WEB_ROOT "/www"

RUN apk update --progress --purge \
    # Install required packages
    # @todo version lock packages
    && apk add --latest --progress --purge \
        autoconf \
        curl \
        dos2unix \
        g++ \
        gcc \
        git \
        gnupg \
        libzip-dev \
        make \
        unzip \
        vim \
        wget

# Install PHP extensions
# @todo version lock extensions
# @todo move dev specific extensions to dev environment
RUN pecl install \
    xdebug-2.9.6 \
    zip

# Enable PHP extensions
# @todo move dev specific extensions to dev environment
RUN docker-php-ext-enable xdebug

# Copy PHP config files
COPY ./docker/app/php/conf.d/* /usr/local/etc/php/conf.d
COPY ./docker/app/php/php.ini /usr/local/etc/php

# Create Xdebug log file
# @todo find a way to not give full access to the log file
# @todo move this to dev environment installer
RUN touch /var/log/xdebug.log \
    && chmod 777 /var/log/xdebug.log

# Install Composer
# @todo find a way to not use Composer globally
# @todo move to dev environment installer
COPY ./docker/app/scripts/composer-installer.sh ${USER_DIRECTORY}/composer-installer

RUN chmod +x ${USER_DIRECTORY}/composer-installer \
    && dos2unix ${USER_DIRECTORY}/composer-installer \
    && ${USER_DIRECTORY}/composer-installer \
    && mv composer.phar /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer \
    && echo "{}" > ${USER_DIRECTORY}/.composer/composer.json \
    && composer config --global repo.packagist composer ${COMPOSER_PACKAGIST_REPO_URL} \
    && rm ${USER_DIRECTORY}/composer-installer

# Install Node / NPM / Yarn
# @todo rather use the Node service or move to dev environment installer
COPY ./docker/app/scripts/node-installer.sh ${USER_DIRECTORY}/node-installer

RUN chmod +x ${USER_DIRECTORY}/node-installer \
    && dos2unix ${USER_DIRECTORY}/node-installer \
    && ${USER_DIRECTORY}/node-installer \
    && rm ${USER_DIRECTORY}/node-installer