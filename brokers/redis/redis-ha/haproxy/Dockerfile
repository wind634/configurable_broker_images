FROM daocloud.io/daocloud/haproxy-redis:v2

ENV HAPROXY_MAXCONN=4096
ENV HAPROXY_CONNECT_TIMEOUT=5000
ENV HAPROXY_SERVER_TIMEOUT=50000
ENV HAPROXY_CLIENT_TIMEOUT=50000
ENV HAPROXY_BALANCE=roundrobin

COPY ./config/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
