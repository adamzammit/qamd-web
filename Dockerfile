FROM php:7.1-apache

MAINTAINER adam.zammit@acspri.org.au

ENV PATH $PATH:/root/.composer/vendor/bin

# PHP extensions come first, as they are less likely to change between Yii releases
RUN mkdir -p /usr/share/man/man1 \ 
    && apt-get update \
    && apt-get -y install \
            git \
            build-essential \ 
            gcc \
            autoconf \
            automake \
            libtool \
            llvm-3.9-dev \
            libclang-3.9-dev \
            clang-3.9 \
            g++ \
            libicu-dev \
            libmcrypt-dev \
            zlib1g-dev \
            libpng-dev \ 
            libjpeg-dev \
            unzip \
            mysql-client \
            sendmail \
            curl \
            gettext \
	    libcurl4-gnutls-dev \
        --no-install-recommends \

    # Enable mod_rewrite
    && a2enmod rewrite \

    # Install PHP extensions
    && docker-php-ext-install intl \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install mcrypt \
    && docker-php-ext-install mysqli \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install opcache \
    && docker-php-ext-install zip \
    && docker-php-ext-install curl \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-install gd \
    && pecl install apcu-5.1.8 && echo extension=apcu.so > /usr/local/etc/php/conf.d/apcu.ini \

    && rm -r /var/lib/apt/lists/* \

    # Fix write permissions with shared folders
    && usermod -u 1000 www-data

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
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer.phar \
    && composer.phar global require --no-progress "fxp/composer-asset-plugin:~1.2.2" \
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
    RUST_VERSION=1.28.0

RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='f69dafcca62fe70d7882113e21bb96a2cbdf4fc4636d25337d6de9191bdec8da' ;; \
        armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='eee969b9fd128e8dc9b4ec44acde46735cf8e612d06495e9d022517849aba2d6' ;; \
        arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='cdc48b7882582fd8475107a406dd86df85c7d72e5deea99ff8940c8e11531285' ;; \
        i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='3bad3945452509ac28ba4113e198323daab57488d6885bb31ac30c9eecd88825' ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.13.0/${rustArch}/rustup-init"; \
    curl "$url" -sSf -o rustup-init; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --default-toolchain $RUST_VERSION; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

RUN cd /usr/src \
    && git clone https://github.com/WizardMac/ReadStat.git \
    && git clone https://github.com/Raymanns/qamd.git

RUN cd /usr/src/ReadStat \
    && ./autogen.sh \
    && ./configure \
    && make \
    && make install

RUN cd /usr/src/qamd \
    && cargo build --release

RUN ldconfig

ENV PATH $PATH:/usr/src/qamd/target/release

WORKDIR /var/www/html

# Composer packages are installed outside the app directory /var/www/html.
# This way developers can mount the source code from their host directory
# into /var/www/html and won't end up with an empty vendors/ directory.
COPY composer.json /var/www/html/
COPY composer.lock /var/www/html/
RUN composer install --prefer-dist --no-progress \
    && rm composer.*

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat

# ENTRYPOINT resets CMD
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
