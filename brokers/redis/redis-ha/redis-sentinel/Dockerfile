FROM daocloud.io/daocloud/redis-sentinel:v2

ENV REDIS_SENTINEL_MASTER_NAME_0=mymaster

COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["redis-sentinel"]
