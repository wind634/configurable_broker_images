# configurable_broker_images
中间件可配置化镜像
    `VERSION 1.0.0`
# 一.TOMCAT

## 1.server.xml 涉及的环境变量

| 环境变量名称        |   描述    |  类型  |  取值范围 | 默认值
| --------   | -----   | :----: | :----: | :----: |
| TOMCAT_SERVER_URI_ENCODING        | 字符编码      |   字符串类型    |  UTF8/GBK/ISO-8859-1 |  UTF8 |
| TOMCAT_SERVER_CONNECTION_TIMEOUT        | 连接超时时间（毫秒）     |   数字类型    |  正整数 | 200000  |
| TOMCAT_SERVER_MAX_THREADS        | 最大线程数      |   数字类型    | 正整数  |  |
| TOMCAT_SERVER_MIN_SPARE_THREADS        | 最小空闲线程数      |   数字类型    |  正整数 |  |
| TOMCAT_SERVER_DISABLE_UPLOAD_TIMEOUT        | 上传超时机制      |   可选类型    |  false/true | false  |
| TOMCAT_SERVER_CONNECTION_UPLOAD_TIMEOUT        | 上传超时时间（毫秒）     |   数字类型    | 正整数  |   |
| TOMCAT_SERVER_ENABLE_LOOKUPS        | 是否反查询域名      |   可选类型     |  false/true | true  |
| TOMCAT_SERVER_KEEP_ALIVE_TIMEOUT        | 连接最大保持时间（毫秒）      |   数字类型    | 正整数  |   |
| TOMCAT_SERVER_COMPRESSION        | 响应的数据进行 GZIP 压缩       |   可选类型    | off/on/force | off  |
| TOMCAT_SERVER_COMPRESSABLE_MIME_TYPE        | 压缩类型      |   字符串    |  字符串  |  ""  |

* TOMCAT_SERVER_COMPRESSABLE_MIME_TYPE 类型示例: `text/html,text/xml,text/javascript,text/css,text/plain,image/gif,image/jpg,image/png`
* 时间相关单位统一为毫秒

## 2.context.xml 涉及的环境变量

| 环境变量名称        |   描述    |  类型  |  取值范围| 默认值
| --------   | -----   | :----: | :----: | :----: |
| TOMCAT_CONTEXT_RESOURCE        | jndi数据源配置      |   字符串类型    |  字符串 |  "" |

* TOMCAT_CONTEXT_RESOURCE 字符串格式类似这样 用 jndiname | username | password | drive_class_name | url；允许空格
* 示例 `jndiname1 | root | 634234 | com.mysql.jdbc.Driver | jdbc:mysql://localhost:3306/testSite;jndiname2 | root | 634234 | com.mysql.jdbc.Driver | jdbc:mysql://localhost:3306/testSite2`
* jndiname, 指定的jndi名称, 字符串类型
* username, 数据库用户名, 字符串类型
* password, 数据库密码, 字符串类型
* drive_class_name, 数据库驱动类名称, 字符串类型
* url, 数据库uri, 字符串类型


## 3.catalina.sh 涉及的环境变量

| 环境变量名称        |   描述    |  类型  |  取值范围 | 默认值
| --------   | -----   | :----: | :----: | :----: |
| TOMCAT_CATALINA_JVM_XMS        | 初始堆大小(kb)      |   数字类型    |  512*1024kb~内存上限  |  内存上限3/4   |
| TOMCAT_CATALINA_JVM_XMX        | 最大堆大小(kb)      |   数字类型    |  512*1024kb~内存上限 | 内存上限3/4    |
| TOMCAT_CATALINA_JVM_XSS        | 每个线程的栈大小(kb)      |   数字类型    |  128k以上 |  1024kb    |
* 单位统一为kb

# 二.ZOOKEEPER

## 1.zookeeper 配置
| 环境变量名称        |   描述    |  类型  |  取值范围 | 默认值
| --------   | :-----   | :----: | :----: | :----: |
| ZOO_TICK_TIME        | server端通信心跳间隔时间, 以毫秒为单位      |   数字类型   | 正整数 | 2000 |
| ZOO_INIT_LIMIT        | 集群中的follower和leader初始连接时能容忍的最多心跳数（tickTime的数量）     |   数字类型    | 正整数  | 5 |
| ZOO_SYNC_LIMIT        | 集群中的follower服务器与leader服务器之间请求和应答之间能容忍的最多心跳数   |   数字类型    |  正整数 |  2 |
| ZOO_SERVERS        | 集群的server配置      |   字符串类型    |  字符串 | "" |

* ZOO_SERVERS配置示例: `server.1=zoo1:2888:3888 server.2=zoo2:2888:3888 server.3=zoo3:2888:3888`

## 2.zookeeper jvm配置
| 环境变量名称        |   描述    |  类型  |  取值范围 | 默认值
| --------   | -----   | :----: | :----: | :----: |
| ZOO_JVM_XMS        | 初始堆大小(kb)      |   数字类型    |  64*1024~内存上限 |  内存限制3/4   |
| ZOO_JVM_XMX        | 最大堆大小(kb)      |   数字类型    |  64*1024~内存上限 |  内存限制3/4   |
| ZOO_JVM_XSS        | 每个线程的栈大小(kb)      |   数字类型    |  228kb以上 |    |


# 三.MYSQL

## /etc/mysql/conf.d 下的conf配置
| 环境变量名称        |   描述    |  类型  |  取值范围 | 默认值
| --------   | :-----   | :----: | :----: |:----: |
| MYSQL_MAX_CONNECTIONS       | 最大连接数     |   数字类型    |   正整数 | 100 |
| MYSQL_QUERY_CACHE_SIZE        | 查询缓存大小     |   数字类型    |  0~小于内存上限 | 0|
| MYSQL_CONNECT_TIMEOUT        | 连握手的超时时间   |   数字类型    |  自然数 | 10 |
| MYSQL_WAIT_TIMEOUT        | 服务器关闭非交互连接之前等待活动秒数      |   数字类型    |  正整数  | 28800|

* 时间单位统一为秒，内存大小单位统一为kb
