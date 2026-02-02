# db-backup-docker

Docker container for scheduled MySQL and PostgreSQL database backups to S3-compatible storage.

## Features

- Supports multiple MySQL and PostgreSQL instances
- Cron-based scheduling
- Streams dump through gzip (low memory usage)
- Uploads to any S3-compatible storage (AWS S3, MinIO, Cloudflare R2, etc.)
- Optional automatic cleanup of old backups
- Multi-arch: `amd64` / `arm64`

## Quick Start

```bash
docker run -d \
  -e MYSQL_DATABASES="host:3306:root:password:db1,db2" \
  -e S3_BUCKET="my-backups" \
  -e S3_ENDPOINT="https://s3.amazonaws.com" \
  -e S3_ACCESS_KEY="your-access-key" \
  -e S3_SECRET_KEY="your-secret-key" \
  -e S3_REGION="us-east-1" \
  -e CRON_SCHEDULE="0 2 * * *" \
  ghcr.io/your-username/db-backup-docker:main
```

## Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `MYSQL_DATABASES` | No* | - | MySQL connection strings |
| `PG_DATABASES` | No* | - | PostgreSQL connection strings |
| `S3_BUCKET` | Yes | - | S3 bucket name |
| `S3_ENDPOINT` | Yes | - | S3 endpoint URL |
| `S3_ACCESS_KEY` | Yes | - | S3 access key |
| `S3_SECRET_KEY` | Yes | - | S3 secret key |
| `S3_REGION` | No | - | S3 region |
| `S3_PREFIX` | No | - | Key prefix for uploaded files |
| `CRON_SCHEDULE` | No | `0 2 * * *` | Cron expression |
| `BACKUP_ON_START` | No | `false` | Run backup immediately on start |
| `BACKUP_RETENTION_DAYS` | No | - | Auto-delete backups older than N days |

\* At least one of `MYSQL_DATABASES` or `PG_DATABASES` must be set.

## Database Connection Format

Multiple servers are separated by `|`, multiple databases by `,`:

```
host:port:user:password:db1,db2|host2:port:user:password:db3
```

Examples:

```bash
# Single MySQL server, two databases
MYSQL_DATABASES="mysql.example.com:3306:root:pass:app_db,analytics_db"

# Two PostgreSQL servers
PG_DATABASES="pg1.example.com:5432:postgres:pass:main|pg2.example.com:5432:postgres:pass:logs"
```

## Docker Compose

```yaml
services:
  db-backup:
    image: ghcr.io/your-username/db-backup-docker:main
    environment:
      MYSQL_DATABASES: "mysql:3306:root:${MYSQL_PASSWORD}:mydb"
      PG_DATABASES: "postgres:5432:postgres:${PG_PASSWORD}:mydb"
      S3_BUCKET: my-backups
      S3_ENDPOINT: https://s3.amazonaws.com
      S3_ACCESS_KEY: ${S3_ACCESS_KEY}
      S3_SECRET_KEY: ${S3_SECRET_KEY}
      S3_REGION: us-east-1
      S3_PREFIX: "db-backups/"
      CRON_SCHEDULE: "0 2 * * *"
      BACKUP_RETENTION_DAYS: "30"
    restart: unless-stopped
```

## Manual Backup

To trigger a backup manually on a running container:

```bash
docker exec <container_name> backup
```

## S3 File Structure

```
s3://my-backups/
  └── db-backups/
      ├── mysql/
      │   └── mysql_host_dbname_20240101_020000.sql.gz
      └── postgres/
          └── pg_host_dbname_20240101_020000.sql.gz
```

## License

MIT
