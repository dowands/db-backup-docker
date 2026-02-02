#!/bin/sh
set -e

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_DIR="/tmp/backups"
mkdir -p "$BACKUP_DIR"

# Backup MySQL databases
# MYSQL_DATABASES format: host:port:user:password:db1,db2|host2:port:user:password:db3
backup_mysql() {
  if [ -z "$MYSQL_DATABASES" ]; then
    return
  fi

  echo "$MYSQL_DATABASES" | tr '|' '\n' | while IFS=: read -r host port user password databases; do
    [ -z "$host" ] && continue
    port=${port:-3306}

    echo "$databases" | tr ',' '\n' | while read -r db; do
      [ -z "$db" ] && continue
      FILENAME="mysql_${host}_${db}_${TIMESTAMP}.sql.gz"
      log "Backing up MySQL: ${host}/${db}"

      mysqldump -h "$host" -P "$port" -u "$user" -p"$password" \
        --single-transaction --quick --lock-tables=false \
        "$db" | gzip > "${BACKUP_DIR}/${FILENAME}"

      upload_to_s3 "${BACKUP_DIR}/${FILENAME}" "${S3_PREFIX}mysql/${FILENAME}"
      rm -f "${BACKUP_DIR}/${FILENAME}"
      log "Done: ${FILENAME}"
    done
  done
}

# Backup PostgreSQL databases
# PG_DATABASES format: host:port:user:password:db1,db2|host2:port:user:password:db3
backup_postgres() {
  if [ -z "$PG_DATABASES" ]; then
    return
  fi

  echo "$PG_DATABASES" | tr '|' '\n' | while IFS=: read -r host port user password databases; do
    [ -z "$host" ] && continue
    port=${port:-5432}

    export PGPASSWORD="$password"

    echo "$databases" | tr ',' '\n' | while read -r db; do
      [ -z "$db" ] && continue
      FILENAME="pg_${host}_${db}_${TIMESTAMP}.sql.gz"
      log "Backing up PostgreSQL: ${host}/${db}"

      pg_dump -h "$host" -p "$port" -U "$user" -d "$db" \
        --no-password | gzip > "${BACKUP_DIR}/${FILENAME}"

      upload_to_s3 "${BACKUP_DIR}/${FILENAME}" "${S3_PREFIX}postgres/${FILENAME}"
      rm -f "${BACKUP_DIR}/${FILENAME}"
      log "Done: ${FILENAME}"
    done

    unset PGPASSWORD
  done
}

upload_to_s3() {
  local src="$1"
  local dest="$2"
  local s3_path="s3://${S3_BUCKET}/${dest}"

  log "Uploading to ${s3_path}"

  aws s3 cp "$src" "$s3_path" \
    --endpoint-url "${S3_ENDPOINT}" \
    --no-progress
}

# Cleanup old backups if retention is set
cleanup_s3() {
  if [ -z "$BACKUP_RETENTION_DAYS" ]; then
    return
  fi

  log "Cleaning up backups older than ${BACKUP_RETENTION_DAYS} days"

  cutoff_date=$(date -d "-${BACKUP_RETENTION_DAYS} days" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || \
    date -v-"${BACKUP_RETENTION_DAYS}"d '+%Y-%m-%dT%H:%M:%S' 2>/dev/null)

  if [ -z "$cutoff_date" ]; then
    log "Warning: could not compute cutoff date, skipping cleanup"
    return
  fi

  aws s3 ls "s3://${S3_BUCKET}/${S3_PREFIX}" --recursive \
    --endpoint-url "${S3_ENDPOINT}" | while read -r line; do
    file_date=$(echo "$line" | awk '{print $1"T"$2}')
    file_path=$(echo "$line" | awk '{print $4}')

    if [ "$file_date" \< "$cutoff_date" ] && [ -n "$file_path" ]; then
      log "Deleting old backup: ${file_path}"
      aws s3 rm "s3://${S3_BUCKET}/${file_path}" \
        --endpoint-url "${S3_ENDPOINT}"
    fi
  done
}

# Validate required env vars
validate() {
  if [ -z "$MYSQL_DATABASES" ] && [ -z "$PG_DATABASES" ]; then
    log "Error: At least one of MYSQL_DATABASES or PG_DATABASES must be set"
    exit 1
  fi

  if [ -z "$S3_BUCKET" ]; then
    log "Error: S3_BUCKET is required"
    exit 1
  fi
}

validate
log "Starting backup..."
backup_mysql
backup_postgres
cleanup_s3
log "All backups completed."
