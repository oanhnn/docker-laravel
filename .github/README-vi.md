# oanhnn/docker-laravel

Docker image dựa trên Alpine OS để chạy [Laravel](https://laravel.com).

[![Build Status](https://github.com/oanhnn/docker-laravel/workflows/CI/badge.svg)](https://github.com/oanhnn/docker-laravel/actions)
[![Software License](https://img.shields.io/github/license/oanhnn/docker-laravel.svg)](https://github.com/oanhnn/docker-laravel/blob/master/LICENSE)

## Tính năng

- [x] Tạo từ Docker image gốc của PHP
- [x] Đã cài đặt sẵn một số [PHP extensions](#extensions) cần thiết
- [x] Đã cài đặt sẵn XDebug extension nhưng mặc định nó được tắt
- [x] Thêm tệp `artisan` để thực hiện lệnh `php /var/www/artisan`
- [x] Tự động tạo vòng lặp vô hạn khi chạy lệnh `artisan schedule:run` với tham số `--sleep`
- [x] Tự động tạo Docker image và đẩy lên Docker hub bởi GitHub Workflows
- [x] Gán nhãn theo quy định của [sermatic version](https://semver.org/spec/v2.0.0.html)

## Nhãn

Image `oanhnn/laravel`

- `X.Y.Z`  - the PATH version (git tag `vX.Y.Z`)
- `X.Y`    - the MINOR version 
- `X`      - the MAJOR version
- `latest` - the latest version

Image `ghcr.io/oanhnn/laravel`

- `edge`         - the edge version, được tạo từ code mới nhất của nhánh `master`
- `nightly`      - the nightly version, được tạo hàng ngày từ code mới nhất của nhánh `master` vào 8:20 AM UTC

> CHÚ Ý: Hãy sử dụng sermatic version cho sản phẩm (VD: `3.1`)

## Cách sử dụng

### Sử dụng giống PHP docker image

Docker image này được sử dụng như [PHP docker image](https://hub.docker.com/_/php)

### Extensions

Các extensions đã được cài đặt bật sẵn:

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

### Bặt XDebug extension

Tạo tệp `xdebug.ini` có nội dung như sau và mount (hoặc copy) tới thư mục `/usr/local/etc/php/conf.d/` trong container

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

Cấu hình IDE của bạn để [làm việc với XDebug](https://devilbox.readthedocs.io/en/latest/intermediate/configure-php-xdebug/linux/vscode.html).

### Chạy lệnh artisan

```shell
$ docker run --rm -it -v $(pwd):/var/www oanhnn/laravel artisan inspire
```

### Chạy lệnh artisan schedule:run với vòng lặp vô hạn

Để tạo vòng lặp vô hạn chạy lệnh `artisan schedule:run`, bạn cần thêm tham số `--sleep <seconds>`. Trong đó `<seconds>` là số giây nghỉ giữa 2 vòng lặp.

```shell
$ docker run --rm -d -v $(pwd):/var/www oanhnn/laravel artisan schedule:run --verbose --sleep 60
```

> NOTE: Tính năng này giống với lệnh `artisan schedule:work` trong Laravel 8+

### Làm việc với docker-compose

Bạn có thể sao chép tất các các tệp trong thư mục `example` tới thư mục gốc của dự án và chạy `docker-compose up -d`.

### Chạy với UID=1000

Mặc định khi `oanhnn/laravel` chạy:

 - PHP-FPM chạy với quyền của người dùng là `www-data` (UID=82)
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

 - Tất cả các lệnh artisan thông qua `/usr/local/bin/artisan` sẽ chạy với quyền của người dùng là `www-data` (bởi lệnh `su-exec`)
   ```shell
   $ docker-compose exec horizon ps
   PID   USER     TIME  COMMAND
       1 root      0:00 {artisan} /bin/sh /usr/local/bin/artisan horizon
       7 www-data  0:00 php /var/www/artisan horizon
      14 www-data  0:00 /usr/local/bin/php artisan horizon:supervisor bb9e6284106d
      25 www-data  0:00 /usr/local/bin/php artisan horizon:work redis --name=defau
      38 root      0:00 ps
   ```

 - Cách lệnh khác sẽ chạy với quyền của người dùng `root`

Tuy nhiên, bạn cũng có thể thiết lập để nó chạy với UID khác. Xem ví dụ bên dưới.

```dockerfile
FROM oanhnn/laravel:edge

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


## Đóng góp

Mọi mã nguồn đóng góp phải thông qua một pull request và được đồng ý bởi một trong các người phát triển chính trước khi được hợp nhất.
Điều này nhằm đảm bảo mọi mã nguồn đều được xem xét cẩn thận.

Fork dự án, tạo nhánh tính năng và gửi một pull request.

Nếu bạn muốn giúp đỡ, hãy tìm kiếm trong [danh sách các vấn đề](https://github.com/oanhnn/docker-laravel/issues).

## Giấy phép

Dự án này được phát hành dưới giấy phép mã nguồn mở MIT.   
Bản quyền thuộc © 2020 [Oanh Nguyen](https://github.com/oanhnn)   
Xem file [License](https://github.com/oanhnn/docker-laravel/blob/master/LICENSE) để biết thêm thông tin.
