FROM daocloud.io/daocloud/mysql-ha:stable

COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["mysqld"]
