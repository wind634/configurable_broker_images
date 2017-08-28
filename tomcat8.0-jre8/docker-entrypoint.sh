#!/bin/bash
# 读取环境变量，并写入到配置文件中，然后加载新的配置文件目录启动服务。
# 第一步，读取环境变量并, shell会自动加载系统环境变量，
# 第二步，判断传入的环境变量是哪种类型的（目前只针对tomcat），
# 有一些是配置tomcat/conf/server.xml文件中的
# 有一些是配置tomcat/conf/context.xml中的（数据源配置）
# 有一些是配置tomcat/bin/catalina.sh中的（jvm配置）
# 判断出不同类型的配置进行不同的操作
# 为了使脚本更具有通用性, 通过环境变量的前缀来判断是何种类型的配置, 然后进行不同的操作
# 因为更通用，所以很多环境变量的设置可能不在预先设置的配置数组里, 这一块
# 因环境变量设置错误而异常的校验没办法在脚本里做，可能要前端或者后台传参
# 数的时候过滤一下

# ====== server.xml 涉及的环境变量 start ======

# TOMCAT_SERVER_URI_ENCODING  字符编码  字符串类型  UTF8/GBK/ISO-8859-1
# TOMCAT_SERVER_CONNECTION_TIMEOUT  连接超时时间   数字类型
# TOMCAT_SERVER_MAX_THREADS  最大线程数   数字类型
# TOMCAT_SERVER_MIN_SPARE_THREADS  最小空闲线程数   数字类型
# TOMCAT_SERVER_DISABLE_UPLOAD_TIMEOUT 上传超时机制 false/true
# TOMCAT_SERVER_CONNECTION_UPLOAD_TIMEOUT 上传超时时间 数字类型
# TOMCAT_SERVER_ENABLE_LOOKUPS  是否反查询域名 false/true
# TOMCAT_SERVER_KEEP_ALIVE_TIMEOUT  连接最大保持时间（毫秒） 数字类型
# TOMCAT_SERVER_COMPRESSION  响应的数据进行 GZIP 压缩 off/on/force
# TOMCAT_SERVER_COMPRESSABLE_MIME_TYPE  压缩类型 text/html,text/xml,text/javascript,text/css,text/plain,image/gif,image/jpg,image/png 

# ====== server.xml 涉及的环境变量 end ======


# ====== context.xml 涉及的环境变量 start ======
# TOMCAT_CONTEXT_RESOURCE jndi数据源配置字符串
# 示例 jndiname1 | root | 634234 | com.mysql.jdbc.Driver | jdbc:mysql://localhost:3306/testSite; jndiname2 | root | 634234 | com.mysql.jdbc.Driver | jdbc:mysql://localhost:3306/testSite2
# ====== context.xml 涉及的环境变量 end ======


# ====== catalina.sh 涉及的环境变量 start ======

# TOMCAT_CATALINA_JVM_XMS  初始堆大小  数字类型
# TOMCAT_CATALINA_JVM_XMX  最大堆大小  数字类型
# TOMCAT_CATALINA_JVM_XSS  每个线程的栈大小  数字类型

# ====== catalina.sh 涉及的环境变量 end ======
val=""

# 读取环境变量的值
get_env(){
	local var="$1"
    local fileVar="${var}_FILE"
	local def="${2:-}"
    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
	val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
    elif [ "${!fileVar:-}" ]; then
        val="$(< "${!fileVar}")"
	fi
	echo $var
	echo $val
	export "$var"="$val"
    unset "$fileVar"
}


# server.xml配置对应的环境变量
server_env=(
    # 默认值
    TOMCAT_SERVER_URI_ENCODING
    TOMCAT_SERVER_CONNECTION_TIMEOUT
)

# context.xml配置对应的环境变量
context_env=()
# catalina.sh配置对应的环境变量
catalina_env=()

# 获取当前系统所有的环境变量
for LINE in `env`  
do   
    # 逐行读取  等号分割   
    env_key=`echo $LINE | cut -d = -f 1`
    # echo $env_key
    case $env_key in
        "TOMCAT_SERVER_"*) 
            if [ $env_key = "TOMCAT_SERVER_URI_ENCODING" -o $env_key = "TOMCAT_SERVER_CONNECTION_TIMEOUT" ]
                then
                    :
                else    
                    server_env+=($env_key)
            fi
        ;;
        "TOMCAT_CONTEXT_"*) 
            context_env+=($env_key)
        ;;
        "TOMCAT_CATALINA_"*) 
            catalina_env+=($env_key)
            echo "数组的元素为: ${catalina_env[@]}"
        ;;
        *) 
            :
        ;;
    esac
    
done

# ============== server.xml 配置 ==============
serverStr=""
# 遍历数组
for ((i=0;i<${#server_env[@]};i++))
do
    arg=${server_env[$i]}
	echo "获取环境变量${arg}的值..."
    get_env $arg
    # 如果取到变量的值
    if [ "$val" = "" ]
    then
        echo '环境变量 '$arg' 未设置'
        case $arg in
            "TOMCAT_SERVER_URI_ENCODING")
                # 如果编码未设置, 默认为utf-8
                serverStr+=" URIEncoding=\\\"UTF8\\\" "
            ;;
            "TOMCAT_SERVER_CONNECTION_TIMEOUT")
                # 默认20000
                serverStr+=" connectionTimeout=\\\"20000\\\" "
            ;;
        esac
    else
    	case $arg in
            # 字符编码
            "TOMCAT_SERVER_URI_ENCODING")
                serverStr+=" URIEncoding=\\\"${val}\\\" "
            ;;
            # 连接超时
            "TOMCAT_SERVER_CONNECTION_TIMEOUT")
                 # 判断是不是数字
                if grep '^[[:digit:]]*$' <<< "$val";then
                   echo "$val is number."
                   serverStr+=" connectionTimeout=\\\"${val}\\\" "
                else
                   echo $arg'值不合法'
                fi
            ;;
            # 最大线程数
    		"TOMCAT_SERVER_MAX_THREADS")
                # 判断是不是数字
                if grep '^[[:digit:]]*$' <<< "$val";then
                   echo "$val is number."
                   serverStr+=" maxThreads=\\\"${val}\\\" "
                else
                   echo $arg'值不合法'
                fi
    		;;
            # 最小线程数
            "TOMCAT_SERVER_MIN_SPARE_THREADS")
                # 判断是不是数字
                if grep '^[[:digit:]]*$' <<< "$val";then
                   echo "$val is number."
                   serverStr+=" minSpareThreads=\\\"${val}\\\" "
                else
                   echo $arg'值不合法'
                fi
            ;;
            # 上传超时机制
            "TOMCAT_SERVER_DISABLE_UPLOAD_TIMEOUT")
                serverStr+=" disableUploadTimeout=\\\"${val}\\\" "
            ;;
            # 上传超时时间
            "TOMCAT_SERVER_CONNECTION_UPLOAD_TIMEOUT")
                if grep '^[[:digit:]]*$' <<< "$val";then
                   echo "$val is number."
                   serverStr+=" connectionUploadTimeout=\\\"${val}\\\" "
                else
                   echo $arg'值不合法'
                fi
            ;;
            # 是否反查询域名
            "TOMCAT_SERVER_ENABLE_LOOKUPS")
                serverStr+=" enableLookups=\\\"${val}\\\" "
            ;;
            # 连接最大保持时间（秒）
            "TOMCAT_SERVER_KEEP_ALIVE_TIMEOUT")
                if grep '^[[:digit:]]*$' <<< "$val";then
                   echo "$val is number."
                   serverStr+=" keepAliveTimeout=\\\"${val}\\\" "
                else
                   echo $arg'值不合法'
                fi
            ;;
            # 响应的数据进行 GZIP 压缩
            "TOMCAT_SERVER_COMPRESSION")
                serverStr+=" compression=\\\"${val}\\\" "
            ;;
            # 压缩类型
            "TOMCAT_SERVER_COMPRESSABLE_MIME_TYPE")
                serverStr+=" compressableMimeType=\\\"${val}\\\" "
            ;;
    		*)
    			serverStr+=" "
    		;;
    	esac
    fi
done

echo $serverStr

# 将serverStr替换进server.xml文件里
sedCmd="s/{{serverArgs}}/${serverStr}/"
echo "$sedCmd"
sed -i "$sedCmd" /usr/local/tomcat/conf/server.xml
# ============== server.xml 配置 ==============

# ============== content.xml 配置 ==============
contextStr=""
# 遍历数组
for ((i=0;i<${#context_env[@]};i++))
do
    arg=${context_env[$i]}
    echo "获取环境变量${arg}的值..."
    get_env $arg
    # 如果取到变量的值
    if [ "$val" = "" ]
    then
        echo '环境变量 '$arg' 未设置'
    else
        case $arg in
            "TOMCAT_CONTEXT_RESOURCE")
                #  去空格
                formatVal=`echo $val | sed s/[[:space:]]//g`
                # 以英文分号";"分隔字符
                formatVal=${formatVal//;/ }    #这里是将var中的,替换为空格
                resourceStr=""
                for element in $formatVal
                do
                    resourceStr+="<Resource type=\\\"javax.sql.DataSource\\\" "
                    echo $element
                    # 以竖线分隔每一个字符串
                    OLD_IFS="$IFS"
                    IFS="|"
                    resourceArgs=($element)
                    IFS="$OLD_IFS"
                    for i in ${!resourceArgs[@]}
                    do
#                       echo ${resourceArgs[$i]}
                        if [ "$i" == "0" ]
                            then
                                # jndi名称
                                resourceStr+=" name=\\\"${resourceArgs[$i]}\\\" "
                        elif [ "$i" == "1" ]
                            then
                                # 数据库用户名
                                resourceStr+=" username=\\\"${resourceArgs[$i]}\\\" "
                        elif [ "$i" == "2" ]
                            then
                                # 数据密码
                                resourceStr+=" password=\\\"${resourceArgs[$i]}\\\" "
                        elif [ "$i" == "3" ]
                            then
                                # jdbc驱动类名称
                                resourceStr+=" driverClassName=\\\"${resourceArgs[$i]}\\\" "
                        elif [ "$i" == "4" ]
                            then
                                # 数据库url
                                resourceStr+=" url=\\\"${resourceArgs[$i]}\\\" "
                        fi
                    done

                    resourceStr+=" />"
                done

                # 格式化带斜杠'/'的字符串
                formatVal=`echo $resourceStr | sed -e 's/\//\\\\\//g'`
                contextStr+=$formatVal" "
            ;;
            *)
                 contextStr+=" "
            ;;
        esac
    fi
done

echo "contextStr:"$contextStr


# 将serverStr替换进server.xml文件里
sedCmd="s/{{Resource}}/${contextStr}/"
echo "$sedCmd"
sed -i "$sedCmd" /usr/local/tomcat/conf/context.xml

# ============== content.xml 配置 ==============

# ============== catalina.sh 配置 ==============
catalinaStr=""
for ((i=0;i<${#catalina_env[@]};i++))
do
    arg=${catalina_env[$i]}
    echo "获取环境变量${arg}的值..."
    get_env $arg
    # 如果取到变量的值
    if [ "$val" = "" ]
    then
        echo '环境变量 '$arg' 未设置'
    else
        case $arg in 
            "TOMCAT_CATALINA_JVM_XMS")
                if grep '^[[:digit:]]*$' <<< "$val";then  
                    catalinaStr+=" -Xms${val}k "
                else  
                    echo $arg'值不合法'  
                fi
            ;;
            "TOMCAT_CATALINA_JVM_XMX")
                if grep '^[[:digit:]]*$' <<< "$val";then  
                    catalinaStr+=" -Xmx${val}k "
                else  
                   echo $arg'值不合法'  
                fi 
            ;;
            "TOMCAT_CATALINA_JVM_XSS")
                if grep '^[[:digit:]]*$' <<< "$val";then  
                    catalinaStr+=" -Xss${val}k "
                else  
                    echo $arg'值不合法'  
                fi 
            ;;
            *)
                catalinaStr+=" "
            ;;
        esac
    fi
done

echo $catalinaStr

sedCmd="s/{{JAVA_OPTS}}/${catalinaStr}/"
echo "$sedCmd"
sed -i "$sedCmd" /usr/local/tomcat/bin/catalina.sh
# ============== catalina.sh 配置 ==============


exec "$@"
