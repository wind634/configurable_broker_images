FROM tomcat:8.0.46-jre8


Add ./config/server.xml  /usr/local/tomcat/conf/server.xml
Add ./config/context.xml  /usr/local/tomcat/conf/context.xml
Add ./config/catalina.sh  /usr/local/tomcat/bin
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh 

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["catalina.sh", "run"]
