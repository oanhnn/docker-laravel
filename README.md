# oanhnn/docker-laravel

## Features

- [x] Build from official PHP docker image
- [x] Installed some [PHP extensions](#extensions)
- [x] Installed XDebug extension but disable by default
- [x] Add `artisan` bin alias to `php /var/www/artisan`
- [x] Auto create infinite loop when run `artisan schedule:run` with option `--sleep`

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
$ docker run --rm -it oanhnn/laravel artisan inspire
```

### Run schedule with infinite loop

```shell
$ docker run --rm -d oanhnn/laravel artisan schedule:run --verbose --sleep 60
```

### Work with docker-compose

You can copy all files in `example` directory to your root directory of project and run `docker-compose up -d`.

### Run with UID=1000

Default `oanhnn/laravel` run:

 - PHP-FPM worker with `www-data` user (UID=82)
   ```shell
   $ docker run --rm -d --name php-fpm oanhnn/laravel:edge
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
FROM oanhnn/laravel:edge

# Create new user with UID=1000 and GID=1000
RUN set -eux; \
    addgroup -g 1000 dev; \
    adduser -u 1000 -D -G dev dev; \

# Set PHP-FPM user
RUN set -eux; \
    sed -i "s|^user =.*|user = dev|i" /usr/local/etc/php-fpm.d/www.conf; \
    sed -i "s|^group =.*|user = dev|i" /usr/local/etc/php-fpm.d/www.conf; \
    chown dev:dev /

# Set artisan commands execute user
ENV EXEC_USER=dev
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
