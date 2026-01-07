#!/bin/sh
set -e

# Move to application directory
cd /var/www/html || exit 0

# Wait for DB to be ready (simple loop)
if [ -n "$DB_HOST" ]; then
  echo "Waiting for database $DB_HOST..."
  n=0
  until php -r "try{new PDO('mysql:host=' . getenv('DB_HOST') . ';port=' . getenv('DB_PORT') . ';dbname=' . getenv('DB_DATABASE'), getenv('DB_USERNAME'), getenv('DB_PASSWORD')); echo 'db-ok'; } catch (Exception $e) { exit(1); }" >/dev/null 2>&1; do
    n=$((n+1))
    if [ "$n" -ge 30 ]; then
      echo "Timed out waiting for database"
      break
    fi
    sleep 1
  done
fi

# Run migrations and seed (idempotent seeders are required)
if [ -f artisan ]; then
  echo "Running migrations..."
  php artisan migrate --force || true
  echo "Seeding database..."
  php artisan db:seed --force || true
fi

# Exec php-fpm as foreground
exec php-fpm
