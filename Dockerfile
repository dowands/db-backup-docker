FROM mysql:8.4 AS mysql-source

FROM debian:bookworm-slim

# Copy MySQL client binaries from official MySQL image
COPY --from=mysql-source /usr/bin/mysqldump /usr/bin/mysqldump
COPY --from=mysql-source /usr/bin/mysql /usr/bin/mysql
COPY --from=mysql-source /usr/lib/mysql/ /usr/lib/mysql/

# Add PostgreSQL official APT repo for latest client
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg \
  && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/pgdg.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    postgresql-client-17 \
    awscli \
    gzip \
    cron \
    tzdata \
    libssl3 \
  && apt-get purge -y curl gnupg \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*

COPY backup.sh /usr/local/bin/backup.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/entrypoint.sh \
  && ln -s /usr/local/bin/backup.sh /usr/local/bin/backup

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
