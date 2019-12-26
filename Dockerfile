# Arguments
ARG BRANCH
ARG COMMIT
ARG DATE
ARG URL
ARG VERSION

# =====================================
# Runtime image
# =====================================
FROM php:7.3-fpm-alpine AS runtime

# Labels
LABEL org.label-schema.schema-version="1.0" \
    org.label-schema.vendor="Oanh Nguyen" \
    org.label-schema.name="oanhnn/laravel" \
    org.label-schema.description="The Docker Image for Laravel application" \
    org.label-schema.url="https://hub.docker.com/r/oanhnn/laravel" \
    org.label-schema.build-date="$DATE" \
    org.label-schema.version="$VERSION" \
    org.label-schema.vcs-url="$URL" \
    org.label-schema.vcs-branch="$BRANCH" \
    org.label-schema.vcs-ref="$COMMIT"

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

# Install some php runtime libraries
RUN set -eux; \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --update --no-cache su-exec ; \
    apk add --update --no-cache --virtual .run-deps $runDeps ; \
    apk del --no-network .build-deps ;


# =====================================
# Develop image
# =====================================
FROM runtime AS develop

# Add user
RUN set -eux; \
    addgroup -g 1000 dev ; \
    adduser -u 1000 -G dev -s /bin/sh -D dev ;

# Install composer
ENV COMPOSER_VERSION=1.9.1
RUN set -eux ; \
    EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)" ; \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" ; \
    ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")" ; \
    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then \
        echo 'ERROR: Invalid installer signature' ; \
        exit 1 ; \
    fi ; \
    php composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION} ; \
    chmod a+x /usr/local/bin/composer ; \
    rm composer-setup.php ;

# Install node
ENV NODE_VERSION=12.14.0
RUN set -eux ; \
    apk add --update --no-cache libstdc++ ; \
    if [ "${ARCH}"=='' && "$(apk --print-arch)"=='x86_64']; then \
        export ARCH=x64 ; \
    fi ; \
    curl -fsSLO --compressed "https://unofficial-builds.nodejs.org/download/release/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz" ; \
    tar -xJf "node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz" -C /usr/local --strip-components=1 --no-same-owner ; \
    ln -s /usr/local/bin/node /usr/local/bin/nodejs ;

# Smoke test
RUN set -eux ; \
    php --version ; \
    php -m ; \
    composer --version ; \
    node --version ;
