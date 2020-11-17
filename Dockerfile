FROM php:7.3-apache

MAINTAINER adam.zammit@acspri.org.au

ENV PATH $PATH:/root/.composer/vendor/bin

# PHP extensions come first, as they are less likely to change between Yii releases
RUN mkdir -p /usr/share/man/man1 \ 
    && apt-get update \
    && apt-get -y install \
            git \
            build-essential \ 
            gcc \
            clang \
            autoconf \
            automake \
            libtool \
            llvm-7-dev \
            libclang-7-dev \
            clang-7 \
            g++ \
            libicu-dev \
            libmcrypt-dev \
            zlib1g-dev \
            libpng-dev \ 
            libjpeg-dev \
            unzip \
            libzip-dev \
            mariadb-client \
            sendmail \
            curl \
            gpg \
            gpg-agent \
            gettext \
            wbritish \
            libssl-dev \
	    libcurl4-gnutls-dev \
        --no-install-recommends \

    # Enable mod_rewrite
    && a2enmod rewrite \

    # Install PHP extensions
    && docker-php-ext-install intl \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install mysqli \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install opcache \
    && docker-php-ext-install zip \
    && docker-php-ext-install curl \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-install gd \
    && pecl install apcu-5.1.19 && echo extension=apcu.so > /usr/local/etc/php/conf.d/apcu.ini \
    && pecl install mcrypt-1.0.3 \
    && docker-php-ext-enable mcrypt \

    # Fix write permissions with shared folders
    && usermod -u 1000 www-data

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt update && apt -y install yarn && rm -r /var/lib/apt/lists/* 

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

#Set PHP defaults for queXS (allow bigger uploads for sample files)
RUN { \
		echo 'memory_limit=256M'; \
		echo 'upload_max_filesize=512M'; \
		echo 'post_max_size=512M'; \
		echo 'max_execution_time=120'; \
        echo 'max_input_vars=10000'; \
        echo 'date.timezone=UTC'; \
        echo 'sendmail_path = /usr/sbin/sendmail -t -i'; \
	} > /usr/local/etc/php/conf.d/uploads.ini

# Next composer and global composer package, as their versions may change from time to time
RUN curl -sS https://getcomposer.org/installer | php -- --version-1.10.17 --filename=composer.phar \
    && mv composer.phar /usr/local/bin/composer.phar \
    && composer.phar global require --no-progress "fxp/composer-asset-plugin:~1.4.6" \
    && composer.phar global require --no-progress "codeception/codeception=2.0.*" \
    && composer.phar global require --no-progress "codeception/specify=*" \
    && composer.phar global require --no-progress "codeception/verify=*"

# Apache config and composer wrapper
COPY apache2.conf /etc/apache2/apache2.conf
COPY composer /usr/local/bin/composer

# Install Rust for qamd
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.40.0

RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='49c96f3f74be82f4752b8bffcf81961dea5e6e94ce1ccba94435f12e871c3bdb' ;; \
        armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='5a2be2919319e8778698fa9998002d1ec720efe7cb4f6ee4affb006b5e73f1be' ;; \
        arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='d93ef6f91dab8299f46eef26a56c2d97c66271cea60bf004f2f088a86a697078' ;; \
        i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='e3d0ae3cfce5c6941f74fed61ca83e53d4cd2deb431b906cbd0687f246efede4' ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.22.1/${rustArch}/rustup-init"; \
    curl "$url" -o rustup-init; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch}; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

RUN cd /usr/src \
    && git clone https://github.com/Raymanns/qamd.git

RUN cd /usr/src/qamd \
    && yarn \
    && cargo build --release

RUN ldconfig

ENV PATH $PATH:/usr/src/qamd/target/release

WORKDIR /var/www/html

# Composer packages are installed outside the app directory /var/www/html.
# This way developers can mount the source code from their host directory
# into /var/www/html and won't end up with an empty vendors/ directory.
COPY composer.json /var/www/html/
#COPY composer.lock /var/www/html/
RUN composer install --prefer-dist --no-progress \
    && rm composer.*

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat

# ENTRYPOINT resets CMD
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
