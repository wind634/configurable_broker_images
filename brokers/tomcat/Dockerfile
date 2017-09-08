FROM daocloud.io/daocloud/tomcat:8.5.15

Add ./config/server.xml  $CATALINA_HOME/conf/server.xml
Add ./config/context.xml  $CATALINA_HOME/conf/context.xml
Add ./config/catalina.sh  $CATALINA_HOME/bin/catalina.sh
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/run.sh"]