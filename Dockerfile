FROM alpine:3.20

RUN apk add --no-cache \
    postgresql16-client \
    aws-cli \
    gzip \
    tzdata \
  && rm -rf /var/cache/apk/*

# Install Oracle MySQL client (supports caching_sha2_password)
RUN wget -qO /tmp/mysql.tar.gz \
    "https://cdn.mysql.com/Downloads/MySQL-8.4/mysql-8.4.4-linux-glibc2.17-$(uname -m).tar.gz" \
  && tar -xzf /tmp/mysql.tar.gz -C /tmp --strip-components=1 \
    --include='*/bin/mysqldump' --include='*/bin/mysql' \
  && mv /tmp/bin/mysqldump /tmp/bin/mysql /usr/local/bin/ \
  && rm -rf /tmp/*

COPY backup.sh /usr/local/bin/backup.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/entrypoint.sh \
  && ln -s /usr/local/bin/backup.sh /usr/local/bin/backup

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
