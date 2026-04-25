FROM php:8.3-apache-bookworm

ENV OHRM_VERSION 5.8
ENV OHRM_MD5 32c08e6733430414a5774f9fefb71902

# ✅ Layer 1: system deps (ít thay đổi)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libfreetype6-dev \
    libjpeg-dev \
    libpng-dev \
    libzip-dev \
    libldap2-dev \
    libicu-dev \
    unzip \
 && rm -rf /var/lib/apt/lists/*

# ✅ Layer 2: PHP extensions (ít thay đổi)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-configure ldap --with-libdir=lib/$(uname -m)-linux-gnu/ \
 && docker-php-ext-install -j "$(nproc)" \
    gd opcache intl pdo_mysql zip ldap

# ✅ Layer 3: download app (hay thay đổi nhất)
RUN set -ex; \
    cd /var/www && rm -rf html; \
    curl -fSL -o orangehrm.zip "https://sourceforge.net/projects/orangehrm/files/stable/${OHRM_VERSION}/orangehrm-${OHRM_VERSION}.zip"; \
    echo "${OHRM_MD5} orangehrm.zip" | md5sum -c -; \
    unzip -q orangehrm.zip "orangehrm-${OHRM_VERSION}/*"; \
    mv orangehrm-$OHRM_VERSION html; \
    rm -rf orangehrm.zip; \
    chown -R www-data:www-data html

# config giữ nguyên
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN a2enmod rewrite

VOLUME ["/var/www/html"]