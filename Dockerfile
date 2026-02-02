FROM mysql:8.4 AS mysql-source

FROM debian:bookworm-slim

# Copy MySQL client binaries from official MySQL image
COPY --from=mysql-source /usr/bin/mysqldump /usr/bin/mysqldump
COPY --from=mysql-source /usr/bin/mysql /usr/bin/mysql
COPY --from=mysql-source /usr/lib/mysql/ /usr/lib/mysql/

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    awscli \
    gzip \
    cron \
    tzdata \
    ca-certificates \
    libssl3 \
  && rm -rf /var/lib/apt/lists/*

COPY backup.sh /usr/local/bin/backup.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/entrypoint.sh \
  && ln -s /usr/local/bin/backup.sh /usr/local/bin/backup

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
