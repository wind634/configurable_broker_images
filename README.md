# configurable_broker_images
中间件可配置化镜像
    `VERSION 1.0.0`

# server.xml 涉及的环境变量

| 环境变量名称        |   描述    |  类型  |  取值范围
| --------   | -----   | :----: | :----: |
| TOMCAT_SERVER_URI_ENCODING        | 字符编码      |   字符串类型    |  UTF8/GBK/ISO-8859-1 |
| TOMCAT_SERVER_CONNECTION_TIMEOUT        | 连接超时时间      |   数字类型    |   |
| TOMCAT_SERVER_MAX_THREADS        | 最大线程数      |   数字类型    |   |
| TOMCAT_SERVER_MIN_SPARE_THREADS        | 最小空闲线程数      |   数字类型    |   |
| TOMCAT_SERVER_DISABLE_UPLOAD_TIMEOUT        | 上传超时机制      |   可选类型    |  false/true |
| TOMCAT_SERVER_CONNECTION_UPLOAD_TIMEOUT        | 上传超时时间      |   数字类型    |   |
| TOMCAT_SERVER_ENABLE_LOOKUPS        | 是否反查询域名      |   可选类型     |  false/true |
| TOMCAT_SERVER_KEEP_ALIVE_TIMEOUT        | 连接最大保持时间（毫秒）      |   数字类型    |   |
| TOMCAT_SERVER_COMPRESSION        | 响应的数据进行 GZIP 压缩       |   可选类型    | off/on/force |
| TOMCAT_SERVER_COMPRESSABLE_MIME_TYPE        | 压缩类型      |   可选类型    |  下注  |

* TOMCAT_SERVER_COMPRESSABLE_MIME_TYPE可选类型为 `text/html,text/xml,text/javascript,text/css,text/plain,image/gif,image/jpg,image/png`

# context.xml 涉及的环境变量

| 环境变量名称        |   描述    |  类型  |  取值范围
| --------   | -----   | :----: | :----: |
| TOMCAT_CONTEXT_RESOURCE        | jndi数据源配置      |   字符串类型    |   |

* TOMCAT_CONTEXT_RESOURCE 字符串格式类似这样 用 jndiname | username | password | drive_class_name | url；允许空格
* 示例 `jndiname1 | root | 634234 | com.mysql.jdbc.Driver | jdbc:mysql://localhost:3306/testSite;jndiname2 | root | 634234 | com.mysql.jdbc.Driver | jdbc:mysql://localhost:3306/testSite2`
* jndiname, 指定的jndi名称, 字符串类型
* username, 数据库用户名, 字符串类型
* password, 数据库密码, 字符串类型
* drive_class_name, 数据库驱动类名称, 字符串类型
* url, 指定的jndi名称, 字符串类型


# catalina.sh 涉及的环境变量

| 环境变量名称        |   描述    |  类型  |  取值范围
| --------   | -----   | :----: | :----: |
| TOMCAT_CATALINA_JVM_XMS        | 初始堆大小      |   数字类型    |   |
| TOMCAT_CATALINA_JVM_XMX        | 最大堆大小      |   数字类型    |   |
| TOMCAT_CATALINA_JVM_XSS        | 每个线程的栈大小      |   数字类型    |   |

