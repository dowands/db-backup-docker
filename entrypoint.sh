#!/bin/sh
set -e

CRON_SCHEDULE="${CRON_SCHEDULE:-0 2 * * *}"

# Configure AWS CLI
aws configure set aws_access_key_id "$S3_ACCESS_KEY"
aws configure set aws_secret_access_key "$S3_SECRET_KEY"
if [ -n "$S3_REGION" ]; then
  aws configure set default.region "$S3_REGION"
fi
aws configure set default.s3.addressing_style "${S3_ADDRESSING_STYLE:-virtual}"

# Export env vars for cron subprocess
env | grep -E '^(MYSQL_|PG_|S3_|BACKUP_|AWS_|HOME|PATH)' > /etc/environment

# Build cron job: source env vars then run backup
echo "${CRON_SCHEDULE} root . /etc/environment; /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1" > /etc/cron.d/db-backup
chmod 0644 /etc/cron.d/db-backup

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup scheduler started. Schedule: ${CRON_SCHEDULE}"

# Run once immediately if requested
if [ "$BACKUP_ON_START" = "true" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running initial backup..."
  /usr/local/bin/backup.sh
fi

# Start cron in foreground
cron -f
