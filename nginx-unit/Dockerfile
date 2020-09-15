# ========================
# Build app image
# ========================
FROM php:7.3-cli-alpine AS runtime

# Update & install some tools
RUN set -eux; \
    apk --update --no-cache add \
        curl \
        su-exec \
    ;

# Install some php extensions
RUN set -eux ; \
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
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
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
    ;

# Install some extensions from PECL
RUN set -eux; \
    pecl update-channels; \
    pecl install \
        imagick \
        redis \
        xdebug \
    ; \
    docker-php-ext-enable imagick redis ; \
    rm -rf /tmp/pear ~/.pearrc ;

# Install NGINX Unit
ENV NGINX_UNIT_VERSION=1.14.0
RUN set -eux; \
    apk add --update --no-cache php7-embed; \
    curl -O https://unit.nginx.org/download/unit-${NGINX_UNIT_VERSION}.tar.gz ; \
    tar xzf unit-${NGINX_UNIT_VERSION}.tar.gz ; \
    cd unit-${NGINX_UNIT_VERSION} ; \
    ./configure \
        --state=/var/lib/unit \
        --log=/var/log/unit.log \
        --control=unix:/run/control.unit.sock \
        --prefix=/usr/local/ \
    ; \
    make; \
    make install; \
    ./configure php \
        --module=php \
        --config=/usr/local/bin/php-config \
        --lib-path=/usr/lib \
    ; \
    make php; \
    make php-install; \
    cd .. ; \
    rm -rf unit-${NGINX_UNIT_VERSION} ;

# Install runtime libraries & clean up
RUN set -eux; \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --update --no-cache --virtual .run-deps $runDeps; \
    apk del --no-network .build-deps php7-embed; \
    rm -rf /var/cache/apk/* ;
