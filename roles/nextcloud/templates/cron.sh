# Run Nextcloud background cron job every 15 minutes
*/15 * * * * sudo -u www-data php -f /var/www/html/occ background:cron

# Run Nextcloud integrity check every day at midnight
0 0 * * * sudo -u www-data php -f /var/www/html/occ integrity:check-core

# Run Nextcloud maintenance repair every Sunday at 3 AM
0 3 * * 0 sudo -u www-data php -f /var/www/html/occ maintenance:repair

# Run Nextcloud db add-missing-indices every day at 2 AM
0 2 * * * sudo -u www-data php -f /var/www/html/occ db:add-missing-indices
