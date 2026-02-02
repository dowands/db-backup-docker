FROM alpine:3.20

RUN apk add --no-cache \
    mysql-client \
    postgresql16-client \
    aws-cli \
    gzip \
    tzdata \
  && rm -rf /var/cache/apk/*

COPY backup.sh /usr/local/bin/backup.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/entrypoint.sh \
  && ln -s /usr/local/bin/backup.sh /usr/local/bin/backup

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
