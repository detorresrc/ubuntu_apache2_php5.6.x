FROM ubuntu:bionic
MAINTAINER Rommel de Torres <detorresrc@gmail.com>

RUN apt update \
    && apt upgrade -y \
    && apt install -y \
    build-essential \
    wget \
    libaprutil1-dev \
    libpcre3-dev \
    liblua5.3-dev \
    libssl-dev \
    libz-dev \
    libmemcached-dev \
    autoconf \
    unzip \
    libxml2-dev \
    libcurl4-openssl-dev \
    libjpeg-dev \
    libpng-dev \
    libxpm-dev \
    libmysqlclient-dev \
    libpq-dev \
    libicu-dev \
    libfreetype6-dev \
    libldap2-dev \
    libxslt-dev \
    libldb-dev \
    && ln -s /usr/include/x86_64-linux-gnu/curl /usr/include/

# Compile Apache
RUN cd /usr/local/src \
    && wget http://mirror.rise.ph/apache//httpd/httpd-2.4.46.tar.bz2 -O httpd-2.4.46.tar.bz2 \
    && tar -xjf  httpd-2.4.46.tar.bz2 \
    && rm httpd-2.4.46.tar.bz2 \
    && cd /usr/local/src/httpd-2.4.46 \
    && ./configure \
    --prefix=/usr/local \
    --enable-ldap=shared \
    --enable-lua=shared \
    --enable-ssl \
    --enable-so \
    --enable-mpms-shared=all \
    && make \
    && make install \
    && rm -Rf /usr/local/src/httpd-2.4.46

# Compile OpenSSL
RUN cd /usr/local/src/ \
    && wget https://ftp.openssl.org/source/old/1.0.2/openssl-1.0.2u.tar.gz -O openssl-1.0.2u.tar.gz \ 
    && cd /usr/local/src \
    && tar -xzf openssl-1.0.2u.tar.gz \
    && cd openssl-1.0.2u \
    && ./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib \
    && make \
    && make install \
    && rm -Rf /usr/local/src/openssl-1.0.2u.tar.gz /usr/local/src/openssl-1.0.2u

# Compile PHP
RUN cd /usr/local/src \
    && wget https://www.php.net/distributions/php-5.6.40.tar.bz2 -O php-5.6.40.tar.bz2 \
    && tar -xjf php-5.6.40.tar.bz2 \
    && cd /usr/local/src/php-5.6.40 \
    && ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/etc \
    --with-apxs2=/usr/local/bin/apxs \
    --enable-mbstring \
    --with-curl \
    --with-xmlrpc \
    --enable-soap \
    --enable-zip \
    --with-gd \
    --with-jpeg-dir \
    --with-png-dir \
    --with-mysql=mysqlnd \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --with-freetype-dir \
    --enable-intl \
    --with-xsl \
    --with-zlib \
    --with-openssl=/usr/local/ssl \
    --enable-opcache \
    --enable-fpm \
    --with-fpm-user=www-data \
    --with-fpm-group=www-data \
    && make \
    && make install \
    && rm -Rf /usr/local/src/php-5.6.40.tar.bz2 /usr/local/src/php-5.6.40

# Install PHP Memcached
RUN cd /usr/local/src \
    && wget https://github.com/php-memcached-dev/php-memcached/archive/2.2.0.zip -O php-memcached-2.2.0.zip \
    && unzip php-memcached-2.2.0.zip \
    && cd php-memcached-2.2.0 \
    && PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/php/bin/ \
    && /usr/local/php/bin/phpize \
    && ./configure \
    && make \
    && make install \
    && rm -Rf /usr/local/src/php-memcached-2.2.0.zip /usr/local/src/php-memcached-2.2.0

VOLUME ["/var/www"]
WORKDIR /var/www

COPY config/httpd.conf /usr/local/conf/
COPY config/httpd-mpm.conf /usr/local/conf/extra/httpd-mpm.conf
COPY config/php.conf /usr/local/conf/extra/php.conf
COPY config/security.conf /usr/local/conf/extra/security.conf
COPY config/cache.conf /usr/local/conf/extra/cache.conf
COPY config/php.prod.ini /usr/local/etc/php.ini
COPY src/index.php /var/www/

# Setup supervisor
RUN apt install -y supervisor
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY scripts/* /usr/local/bin/
RUN chmod +x /usr/local/bin/apache2.sh

EXPOSE 80
EXPOSE 8080

CMD ["/usr/bin/supervisord"]