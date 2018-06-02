FROM php:7.1-apache

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG DEBUG_PORT=9001
ARG WP_INSTALL_DIR=/var/www/html

# Change user
RUN usermod -u $USER_ID -s /bin/bash www-data && \
groupmod -g $GROUP_ID www-data && \
chown www-data.www-data /var/www

# Install dependencies
RUN apt-get update && apt-get -y install --no-install-recommends \
build-essential \
nodejs \
git \
gnupg \
zlib1g-dev \
fontforge \
ruby ruby-dev \
libcurl4-gnutls-dev \
libpng-dev \
libmcrypt-dev \
libxml2-dev

# Add nodejs repo
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -

# Add Yarn repo
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Install Node, NPM and Yarn
RUN apt-get update && apt-get -y install --no-install-recommends \
nodejs \
yarn

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

# Install php required php extensions
RUN docker-php-ext-install bcmath curl gd json mbstring mcrypt mysqli xml zip
RUN pecl install xdebug && docker-php-ext-enable xdebug

# Setup xdebug
COPY xdebug.ini /tmp/xdebug.ini
RUN cat /tmp/xdebug.ini >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
rm /tmp/xdebug.ini

# Fontcustom
RUN git clone https://github.com/bramstein/sfnt2woff-zopfli.git sfnt2woff-zopfli && \
cd sfnt2woff-zopfli && \
make && \
mv sfnt2woff-zopfli /usr/local/bin/sfnt2woff && \
cd -
RUN git clone --recursive https://github.com/google/woff2.git && \
cd woff2 && \
make clean all && \
mv woff2_compress /usr/local/bin/ && \
mv woff2_decompress /usr/local/bin/ && \
cd -
RUN gem install fontcustom

# npm globals
RUN npm install -g gulp-cli bower

# Clear apt meta`
RUN rm -r /var/lib/apt/lists/*

WORKDIR /var/www/html

VOLUME ["/var/www"]

EXPOSE 80 $DEBUG_PORT
