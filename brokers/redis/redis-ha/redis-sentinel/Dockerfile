FROM daocloud.io/daocloud/redis-sentinel:v2

COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["redis-sentinel"]
