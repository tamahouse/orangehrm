FROM php:8.3-apache-bookworm

ENV OHRM_VERSION=5.8

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

# ✅ 👇 QUAN TRỌNG: copy zip (layer cache tốt)
COPY orangehrm.zip /tmp/orangehrm.zip

# ✅ Layer 3: extract app (hay thay đổi nhất)
RUN set -ex; \
    rm -rf /var/www/html; \
    cd /var/www; \
    unzip -q /tmp/orangehrm.zip; \
    mv orangehrm-* html; \
    rm /tmp/orangehrm.zip; \
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