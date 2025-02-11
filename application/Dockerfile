ARG php_version=8.2

FROM composer AS php_deps
COPY composer.json composer.lock ./
RUN composer install --no-scripts

FROM node:alpine AS build_assets
WORKDIR /app
COPY . /app
RUN npm ci && npm run build

FROM php:${php_version}-fpm
WORKDIR /var/www/html
COPY --from=build_assets --chown=www-data app .
COPY --from=php_deps --chown=www-data app/vendor ./vendor
