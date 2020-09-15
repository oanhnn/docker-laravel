# oanhnn/docker-laravel

## Features

- [x] Build from official PHP docker image
- [x] Installed some [PHP extensions](#extensions)
- [x] Installed XDebug extension but disable by default
- [x] Add `artisan` bin alias to `php /var/www/artisan`
- [x] Auto create infinite loop when run `artisan schedule:run` with option `--sleep`

## Extensions

```shell
$ php -m
```

## Usage

### Use like official PHP docker image

Use like with official PHP image

### Enable XDebug

Create a `xdebug.ini` file like below and mount (or copy) to `/usr/local/etc/php/conf.d/` directory in container

```ini
zend_extension=xdebug.so

[Xdebug]
xdebug.remote_enable=true
xdebug.remote_autostart=false
xdebug.remote_port=9000
xdebug.remote_connect_back=false
xdebug.remote_handler=dbgp
xdebug.idekey=CODE
```

Config your IDE to [work with XDebug](https://devilbox.readthedocs.io/en/latest/intermediate/configure-php-xdebug/linux/vscode.html).

### Run artisan command

```shell
$ docker run --rm -it oanhnn/laravel artisan inspire
```

### Run schedule with infinite loop

```shell
$ docker run --rm -d oanhnn/laravel artisan schedule:run --verbose --sleep
```

### Work with docker-compose

```yml
version: '3.5'

# =========================================
# X-Templates
# =========================================
x-app-service: &app-service
  image: oanhnn/laravel
  depends_on:
    - mysql
    - redis
  environment:
    REDIS_HOST:  redis
    DB_HOST:     mysql
    LOG_CHANNEL: stderr
  restart: unless-stopped
  volumes:
    - .:/var/www
    - .env:/var/www/.env

# =========================================
# Networks
# =========================================
networks:
  mysql-net: {}
  redis-net: {}
  proxy-net: {}

# =========================================
# Volumes
# =========================================
volumes:
  mysql-vol: {}
  redis-vol: {}

# =========================================
# Services
# =========================================
services:
  redis:
    image: redis:alpine
    command: redis-server --bind 0.0.0.0 --requirepass ${REDIS_PASSWORD}
    networks:
      - redis-net
    ports:
      - ${REDIS_PORT:-6379}:6379
    restart: unless-stopped
    volumes:
      - redis-vol:/data

  mysql:
    image: mysql:8.0
    # PDO Doesn't support MySQL 8 caching_sha2_password Authentication
    # @see https://dev.mysql.com/doc/refman/8.0/en/upgrading-from-previous-series.html#upgrade-caching-sha2-password
    command:
      - '--default-authentication-plugin=mysql_native_password'
      - '--character-set-server=utf8mb4'
      - '--collation-server=utf8mb4_unicode_ci'
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_PASSWORD}
      MYSQL_USER:          ${DB_USERNAME}
      MYSQL_PASSWORD:      ${DB_PASSWORD}
      MYSQL_DATABASE:      ${DB_DATABASE}
    networks:
      - mysql-net
    ports:
      - ${DB_PORT:-3306}:3306
    restart: unless-stopped
    volumes:
      - mysql-vol:/var/lib/mysql
      - .docker/mysql:/docker-entrypoint-initdb.d

  nginx:
    image: nginx:stable-alpine
    depends_on:
      - php
    networks:
      - proxy-net
    ports:
      - 443:443
      - 8000:80
    volumes:
      - ./:/var/www
      - .docker/nginx/default.conf:/etc/nginx/conf.d/default.conf
      - .docker/nginx/keys:/etc/nginx/ssl

  # This service run php-fpm
  # It using default command in Dockerfile (from php:xx-fpm-alpine)
  php:
    <<: *app-service 
    networks:
      - mysql-net
      - redis-net
      - proxy-net

  # This service run schedule
  # It using `artisan schedule:run` with `--loop` to execute command `php artisan schedule:run` in a infinite loop
  schedule:
    <<: *app-service
    command: artisan schedule:run --verbose --no-interaction --loop 60s
    networks:
      - mysql-net
      - redis-net

  # This service run queue:worker
  # It using `artisan queue:work` or `artisan horizon`
  horizon:
    <<: *app-service
    command: artisan horizon
    networks:
      - mysql-net
      - redis-net

```

## Contributing

All code contributions must go through a pull request and approved by a core developer before being merged. 
This is to ensure proper review of all the code.

Fork the project, create a feature branch, and send a pull request.

If you would like to help take a look at the [list of issues](https://github.com/oanhnn/docker-php/issues).

## License

This project is released under the MIT License.   
Copyright © 2020 [Oanh Nguyen](https://github.com/oanhnn)   
Please see [License File](./LICENSE) for more information.
