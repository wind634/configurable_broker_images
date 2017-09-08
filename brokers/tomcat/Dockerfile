FROM daocloud.io/daocloud/tomcat:8.5.15

RUN mv  /usr/local/tomcat/webapps/ROOT /usr/local/tomcat/webapps/ROOT_BAK
Add ./config/server.xml  /usr/local/tomcat/conf/server.xml
Add ./config/context.xml  /usr/local/tomcat/conf/context.xml
Add ./config/catalina.sh  /usr/local/tomcat/bin
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["catalina.sh", "run"]