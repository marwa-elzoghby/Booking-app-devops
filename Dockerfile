### -----------------------
### Stage 1: Node build
### -----------------------
FROM node:20-alpine AS node-builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN NODE_OPTIONS=--openssl-legacy-provider npm run dev


### -----------------------
### Stage 2: Composer build
### -----------------------
FROM composer:2 AS composer-builder

WORKDIR /app

COPY composer.json composer.lock ./
COPY . .

RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader \
    --ignore-platform-reqs \
    --no-scripts


### -----------------------
### Stage 3: PHP runtime (FINAL IMAGE)
### -----------------------
FROM php:7.4-fpm-alpine

WORKDIR /var/www/html

# Install only required runtime libs
RUN apk add --no-cache \
    libpng \
    libpng-dev \
    libzip \
    libzip-dev \
    zlib \
    zlib-dev \
    oniguruma \
    oniguruma-dev \
    libxml2 \
    libxml2-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    pkgconf \
    build-base \
    zip \
    unzip

# PHP extensions
RUN docker-php-ext-install \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip

# Copy app source

# Copy application source
COPY . .

# Copy vendor from composer stage
COPY --from=composer-builder /app/vendor /var/www/html/vendor

# Copy built assets from node stage
COPY --from=node-builder /app/public /var/www/html/public

# Copy entrypoint and make executable
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Permissions
RUN chown -R www-data:www-data \
    /var/www/html/storage \
    /var/www/html/bootstrap/cache

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
