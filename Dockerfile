### -----------------------
### Stage 1: Node build
### -----------------------
FROM node:20-alpine AS node-builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run dev


### -----------------------
### Stage 2: Composer build
### -----------------------
FROM composer:2 AS composer-builder

WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader

COPY . .


### -----------------------
### Stage 3: PHP runtime (FINAL IMAGE)
### -----------------------
FROM php:7.4-fpm-alpine

WORKDIR /var/www/html

# Install only required runtime libs
RUN apk add --no-cache \
    libpng \
    libzip \
    oniguruma \
    libxml2 \
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
COPY . .

# Copy vendor from composer stage
COPY --from=composer-builder /app/vendor /var/www/html/vendor

# Copy built assets from node stage
COPY --from=node-builder /app/public /var/www/html/public

# Permissions
RUN chown -R www-data:www-data \
    /var/www/html/storage \
    /var/www/html/bootstrap/cache

EXPOSE 9000

CMD ["php-fpm"]
