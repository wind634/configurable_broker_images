FROM daocloud.io/daocloud/redis:ha

RUN rm /usr/local/etc/redis/redis.conf

COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["redis-server"]
