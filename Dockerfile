FROM php:7-apache
MAINTAINER Evrim Cabuk <ecabuk@ecabuk.net>

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG DEBUG_PORT=9001
ARG WP_INSTALL_DIR=/var/www/html

# Change user
RUN usermod -u $USER_ID -s /bin/bash www-data && \
groupmod -g $GROUP_ID www-data && \
chown www-data.www-data /var/www

# Add nodejs repo
RUN curl -sL https://deb.nodesource.com/setup_4.x | bash -

# Install WordPress
RUN curl -sL http://wordpress.org/latest.tar.gz | tar xz -C /tmp && \
rm -rf $WP_INSTALL_DIR && mv /tmp/wordpress $WP_INSTALL_DIR && \
chown -R www-data.www-data $WP_INSTALL_DIR
RUN find $WP_INSTALL_DIR -type d -exec chmod 755 {} \;
RUN find $WP_INSTALL_DIR -type f -exec chmod 644 {} \;

# Install Composer
ADD https://getcomposer.org/installer /tmp/composer-setup.php
RUN php /tmp/composer-setup.php --install-dir=/usr/bin --filename=composer && \
rm /tmp/composer-setup.php

# Install dependencies
RUN apt-get update && apt-get -y install \
build-essential \
nodejs \
git \
woff-tools \
fontforge \
ruby ruby-dev \
libcurl4-gnutls-dev \
libpng12-dev \
libmcrypt-dev \
libxml2-dev \
--no-install-recommends && rm -r /var/lib/apt/lists/*

# Install php required php extensions
RUN docker-php-ext-install bcmath curl gd json mbstring mcrypt mysqli xml zip
RUN pecl install xdebug && docker-php-ext-enable xdebug

# Setup xdebug
COPY xdebug.ini /tmp/xdebug.ini
RUN cat /tmp/xdebug.ini >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
rm /tmp/xdebug.ini

# Fontcustom
RUN gem install fontcustom

# npm globals
RUN npm install -g gulp-cli bower

# Install Debug Proxy
RUN curl -sL http://downloads.activestate.com/Komodo/releases/10.0.0/remotedebugging/Komodo-PythonRemoteDebugging-10.0.0-89159-linux-x86_64.tar.gz | tar xz -C /tmp && \
mv /tmp/Komodo-PythonRemoteDebugging-10.0.0-89159-linux-x86_64 /opt/Komodo-PythonRemoteDebugging && \
ln -s /opt/Komodo-PythonRemoteDebugging/pydbgpproxy /usr/bin/pydbgpproxy

WORKDIR /var/www/html

VOLUME ["/var/www"]

EXPOSE "80" $DEBUG_PORT

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
echo "pydbgpproxy -d 127.0.0.1:9000 -i 0.0.0.0:$DEBUG_PORT" >> /entrypoint.sh

CMD ["/entrypoint.sh"]
