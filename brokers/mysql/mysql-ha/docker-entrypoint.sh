#!/bin/bash
# 用户可以进行配置的环境变量
# MYSQL_MAX_CONNECTIONS     最大连接数
# MYSQL_QUERY_CACHE_SIZE   查询缓存大小
# MYSQL_CONNECT_TIMEOUT    连握手的超时时间
# MYSQL_WAIT_TIMEOUT    服务器关闭非交互连接之前等待活动秒数
# 在/etc/mysql/conf.d目录下新建配置文件

# MYSQL_CONF_FILE_*


# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

CONFIG_DIR="/etc/mysql/conf.d"
CONFIG="$CONFIG_DIR/new_config.cnf"

 #  add env config start
USE_MYSQL_CONF_FILE="false"
mysql_conf_file_array=()

for LINE in `env`
do
    # 逐行读取  等号分割
    env_key=`echo $LINE | cut -d = -f 1`
    case $env_key in
        "MYSQL_CONF_FILE_"*)
            # 只要该环节变量存在,说明是使用配置文件的形式
            USE_MYSQL_CONF_FILE="true"
            mysql_conf_file_array+=($env_key)
        ;;
        *)
            :
        ;;
    esac
done


if [ ! -f "$CONFIG_DIR/new_config.cnf" ]; then
    echo  "[mysqld]" >> "$CONFIG"

    if [ $USE_MYSQL_CONF_FILE == "true" ];then
        # 以配置文件的方式写入
        # 读取每一行环境变量
        # 按照末尾序号进行排序
        len=${#mysql_conf_file_array[@]}
        for((i=0; i<$len; i++)){
          for((j=i+1; j<$len; j++)){
             num1=${mysql_conf_file_array[i]:16}
             num2=${mysql_conf_file_array[j]:16}
            if [[ ${num1} -gt ${num2} ]]
            then
              temp=${mysql_conf_file_array[i]}
              mysql_conf_file_array[i]=${mysql_conf_file_array[j]}
              mysql_conf_file_array[j]=$temp
            fi
          }
        }

        # 重定向到配置文件路径
        for ((i=0;i<${#mysql_conf_file_array[@]};i++))
        do
            arg=${mysql_conf_file_array[$i]}
            var="$arg"
            val=${!var}
            # 每一行进行正则过滤，不符合格式则不写入
            checkedVal=`echo "$val" | grep -E '^(\s*#\s*(\S*\s*)*\s*)|(\s*\w+\s*=\s*\S+\s*)$' `

            if [ -n "$checkedVal" ]; then
                echo "env_file_row ${arg}'s content..."${val}
                echo "$val" >> "$CONFIG"
            fi
        done

    else
        file_env 'MYSQL_MAX_CONNECTIONS'
        if [ -n "$MYSQL_MAX_CONNECTIONS" ];then
            if grep '^[[:digit:]]*$' <<< "$MYSQL_MAX_CONNECTIONS";then
                if [ $MYSQL_MAX_CONNECTIONS -gt 0 ]; then
                    echo  "max_connections=$MYSQL_MAX_CONNECTIONS" >> "$CONFIG"
                fi
            else
                echo "max_connections value is not a number."
            fi
        fi

        file_env 'MYSQL_QUERY_CACHE_SIZE'
        if [ -n "$MYSQL_QUERY_CACHE_SIZE" ];then
            if grep '^[[:digit:]]*$' <<< "$MYSQL_QUERY_CACHE_SIZE";then
                if [ $MYSQL_QUERY_CACHE_SIZE -gt 0 ]; then
                    echo  "query_cache_size=${MYSQL_QUERY_CACHE_SIZE}kb" >> "$CONFIG"
                fi
            else
                echo "query_cache_size value is not a number."
            fi
        fi

        file_env 'MYSQL_CONNECT_TIMEOUT'
        if [ -n "$MYSQL_CONNECT_TIMEOUT" ];then
            if grep '^[[:digit:]]*$' <<< "$MYSQL_CONNECT_TIMEOUT";then
                if [ $MYSQL_CONNECT_TIMEOUT -ge 0 ]; then
                    echo  "connect_timeout=$MYSQL_CONNECT_TIMEOUT" >> "$CONFIG"
                fi
            else
                echo "connect_timeout value is not a number."
            fi
        fi

        file_env 'MYSQL_WAIT_TIMEOUT'
        if [ -n "$MYSQL_WAIT_TIMEOUT" ];then
            if grep '^[[:digit:]]*$' <<< "$MYSQL_WAIT_TIMEOUT";then
                if [ $MYSQL_WAIT_TIMEOUT -gt 0 ]; then
                    echo  "wait_timeout=$MYSQL_WAIT_TIMEOUT" >> "$CONFIG"
                fi
            else
                echo "wait_timeout value is not a number."
            fi
        fi

    fi
fi
#  add env config end

exec "$@"