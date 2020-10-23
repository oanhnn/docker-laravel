# Base stage
FROM php:7.4-fpm-alpine AS base

WORKDIR /var/www

COPY artisan /usr/local/bin/

RUN set -eux; \
    apk --update --no-cache add \
        curl \
        su-exec \
    ; \
    apk add --update --no-cache --virtual .build-deps \
        freetype-dev \
        gmp-dev \
        icu-dev \
        imagemagick-dev \
        libintl \
        libjpeg-turbo-dev \
        libpng-dev \
        libxml2-dev \
        libzip-dev \
        postgresql-dev \
        zlib-dev \
        $PHPIZE_DEPS \
    ; \
    docker-php-ext-configure gd \
        --with-freetype=/usr/include/ \
        --with-jpeg=/usr/include/ \
    ; \
    docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" \
        bcmath \
        gd \
        gmp \
        intl \
        opcache \
        pdo_mysql \
        pdo_pgsql \
        pcntl \
        sockets \
        zip \
    ; \
    \
    pecl update-channels; \
    pecl install \
        imagick \
        redis \
        xdebug \
    ; \
    docker-php-ext-enable imagick redis; \
    rm -rf /tmp/pear ~/.pearrc; \
    \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --update --no-cache --virtual .run-deps $runDeps; \
    apk del .build-deps; \
    \
    php --version

# Test stage
FROM base AS test

RUN set -eux; \
    php -v; \
    php -m; \
    php --ini

# Release stage
FROM base AS release
