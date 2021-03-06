# oanhnn/docker-laravel

Alpine based [Laravel](https://laravel.com) image.

[![Build Status](https://github.com/oanhnn/docker-laravel/workflows/CI/badge.svg)](https://github.com/oanhnn/docker-laravel/actions)
[![Software License](https://img.shields.io/github/license/oanhnn/docker-laravel.svg)](https://github.com/oanhnn/docker-laravel/blob/master/LICENSE)

## Features

- [x] Build from official PHP docker image
- [x] Installed some [PHP extensions](#extensions)
- [x] Installed XDebug extension but disable by default
- [x] Add `artisan` bin alias to `php /var/www/artisan`
- [x] Auto create infinite loop when run `artisan schedule:run` with option `--sleep`
- [x] Auto build and push by Github Workflow
- [x] Tagging follow [sermatic version](https://semver.org/spec/v2.0.0.html)

## Tags

Image `oanhnn/laravel`

- `X.Y.Z`  - the PATH version (git tag `vX.Y.Z`)
- `X.Y`    - the MINOR version 
- `X`      - the MAJOR version
- `latest` - the latest version

Image `ghcr.io/oanhnn/laravel`

- `edge`         - the edge version, it is newest code from branch `master`
- `nightly`      - the nightly version, it is builded daily at 8:20 AM UTC

> NOTE: Using sematic version for production

## Usage

### Use like official PHP docker image

Use like with official [PHP image](https://hub.docker.com/_/php)

### Extensions

All extensions are installed and enabled:

```shell
$ docker run --rm -it oanhnn/laravel:edge php -m
[PHP Modules]
bcmath
Core
ctype
curl
date
dom
fileinfo
filter
ftp
gd
gmp
hash
iconv
imagick
intl
json
libxml
mbstring
mysqlnd
openssl
pcntl
pcre
PDO
pdo_mysql
pdo_pgsql
pdo_sqlite
Phar
posix
readline
redis
Reflection
session
SimpleXML
sockets
sodium
SPL
sqlite3
standard
tokenizer
xml
xmlreader
xmlwriter
Zend OPcache
zip
zlib

[Zend Modules]
Zend OPcache
```

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
$ docker run --rm -it -v $(pwd):/var/www oanhnn/laravel artisan inspire
```

### Run artisan schedule:run with infinite loop

To run `artisan schedule:run` in infinite loop, you MUST add option `--sleep <seconds>`. With `<seconds>` is loop sleep in seconds .

```shell
$ docker run --rm -d -v $(pwd):/var/www oanhnn/laravel artisan schedule:run --verbose --sleep 60
```

> NOTE: This feature like command `artisan schedule:work` in Laravel 8+

### Work with docker-compose

You can copy all files in `example` directory to your root directory of project and run `docker-compose up -d`.

### Run with UID=1000

Default `oanhnn/laravel` run:

 - PHP-FPM worker with `www-data` user (UID=82)
   ```shell
   $ docker run --rm -d --name php-fpm oanhnn/laravel:latest
   b634e56c859837d660ed8697b50e92d3f05efe89325e39c803b731c7f846864f
   $ docker exec php-fpm ps
   PID   USER     TIME  COMMAND
       1 root      0:00 php-fpm: master process (/usr/local/etc/php-fpm.conf)
       6 www-data  0:00 php-fpm: pool www
       7 www-data  0:00 php-fpm: pool www
       8 root      0:00 ps
   ```

 - All artisan command via `/usr/local/bin/artisan` with `www-data` (by `su-exec`)
   ```shell
   $ docker-compose exec horizon ps
   PID   USER     TIME  COMMAND
       1 root      0:00 {artisan} /bin/sh /usr/local/bin/artisan horizon
       7 www-data  0:00 php /var/www/artisan horizon
      14 www-data  0:00 /usr/local/bin/php artisan horizon:supervisor bb9e6284106d
      25 www-data  0:00 /usr/local/bin/php artisan horizon:work redis --name=defau
      38 root      0:00 ps
   ```

 - Other command with root user

However, you can also set run with other UID. See below example.

```dockerfile
FROM oanhnn/laravel:latest

# Create new user with UID=1000 and GID=1000
RUN set -eux; \
    addgroup -g 1000 dev; \
    adduser -u 1000 -D -G dev dev

# Set PHP-FPM user
RUN set -eux; \
    sed -i "s|^user =.*|user = dev|i" /usr/local/etc/php-fpm.d/www.conf; \
    sed -i "s|^group =.*|user = dev|i" /usr/local/etc/php-fpm.d/www.conf; \
    chown dev:dev /var/www

# Set artisan commands execute user
ENV EXEC_USER=dev
```

### Fix permissions when mouting

When mounting file or directory to container, you can have error about file permissions. To fix it, you can run:

```shell
$ sudo setfacl -dR -m u:82:rwX -m u:$(whoami):rwX ./
$ sudo setfacl -R  -m u:82:rwX -m u:$(whoami):rwX ./
```

Or

```shell
$ sudo chmod -R g+w         bootstrap/cache storage
$ sudo chown -R $(whoami):82 bootstrap/cache storage
```

## Contributing

All code contributions must go through a pull request and approved by a core developer before being merged. 
This is to ensure proper review of all the code.

Fork the project, create a feature branch, and send a pull request.

If you would like to help take a look at the [list of issues](https://github.com/oanhnn/docker-laravel/issues).

## Security

If you discover any security related issues, please contact to [me](#contact) instead of using the issue tracker.

## License

This project is available under the [MIT license](https://tldrlegal.com/license/mit-license).

## Contact

Copyright (c) 2021 [Oanh Nguyen](https://github.com/oanhnn)

[![@oanhnn](https://img.shields.io/badge/github-oanhnn-green.svg)](https://github.com/oanhnn) [![@oanhnn](https://img.shields.io/badge/twitter-oanhnn-blue.svg)](https://twitter.com/oanhnn)
