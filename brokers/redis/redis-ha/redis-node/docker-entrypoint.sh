#!/bin/bash
# REDIS_TIMEOUT 客户端请求超时时间
# REDIS_RDB_COMPRESSION 是否使用压缩  yes/no
# REDIS_APPEND_ONLY     是否开启appendonlylog   yes/no
# REDIS_APPEND_FSYNC    appendonlylog如何同步到磁盘  always/everysec/no
# REDIS_MAXMEMORY   可使用的最大内存
# REDIS_MAXMEMORY_POLICY    内存不足时,数据清除策略    volatile-lru / allkeys-lru / volatile-random / allkeys-random / volatile-ttl /  noeviction
# REDIS_PASSWORD 密码

# REDIS_MIN_SLAVES_TO_WRITE
# REDIS_MIN_SLAVES_MAX_LAG

# 在/usr/local/etc/redis/redis.conf 文件中

# REDIS_CONF_FILE_*

# set -e


# config file path
CONFIG_DIR="/usr/local/etc/redis"
CONFIG="$CONFIG_DIR/redis.conf"

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


# first arg is `-f` or `--some-option`
# or first arg is `something.conf`
if [ "${1#-}" != "$1" ] || [ "${1%.conf}" != "$1" ]; then
    set -- $CONFIG "$@"
	set -- redis-server "$@"
fi

# allow the container to be started with `--user`
if [ "$1" = 'redis-server' -a "$(id -u)" = '0' ]; then
	chown -R redis .

	# add redis config start
    USE_REDIS_CONF_FILE="false"
    redis_conf_file_array=()

    for LINE in `env`
    do
        # 逐行读取  等号分割
        env_key=`echo $LINE | cut -d = -f 1`
        case $env_key in
            "REDIS_CONF_FILE_"*)
                # 只要该环节变量存在,说明是使用配置文件的形式
                USE_REDIS_CONF_FILE="true"
                redis_conf_file_array+=($env_key)
            ;;
            *)
                :
            ;;
        esac
    done

    if [ ! -f "$CONFIG" ]; then

         if [ ! -d "$CONFIG_DIR" ]; then
            mkdir $CONFIG_DIR

         fi
        echo "" >> "$CONFIG"
        if [ $USE_REDIS_CONF_FILE == "true" ];then
            # 以配置文件的方式写入
            # 读取每一行环境变量
            # 按照末尾序号进行排序
            len=${#redis_conf_file_array[@]}
            for((i=0; i<$len; i++)){
              for((j=i+1; j<$len; j++)){
                 num1=${redis_conf_file_array[i]:16}
                 num2=${redis_conf_file_array[j]:16}
                if [[ ${num1} -gt ${num2} ]]
                then
                  temp=${redis_conf_file_array[i]}
                  redis_conf_file_array[i]=${redis_conf_file_array[j]}
                  redis_conf_file_array[j]=$temp
                fi
              }
            }

            # 重定向到配置文件路径
            for ((i=0;i<${#redis_conf_file_array[@]};i++))
            do
                arg=${redis_conf_file_array[$i]}
                var="$arg"
                val=${!var}
                # 每一行进行正则过滤，不符合格式则不写入
                checkedVal=`echo "$val" | grep -E '^((\s*#\s*(\S*\s*)*\s*)|(\s*\S+\s+\S+\s*))$' `

                if [ -n "$checkedVal" ]; then
                    echo "env_file_row ${arg}'s content..."${val}
                    echo "$val" >> "$CONFIG"
                fi
            done

        else
            # 请求超时时间 单位为s
            file_env 'REDIS_TIMEOUT'
            if [ -n "$REDIS_TIMEOUT" ];then
                # 大于等于0的数字
                if grep '^[[:digit:]]*$' <<< "$REDIS_TIMEOUT";then
                    if [ $REDIS_TIMEOUT -ge 0 ]; then
                        echo  "timeout $REDIS_TIMEOUT" >> "$CONFIG"
                    fi
                else
                    echo "timeout value is not a number."
                fi
            fi

            # 是否使用压缩 取值yes or no
            file_env 'REDIS_RDB_COMPRESSION'
            if [ -n "$REDIS_RDB_COMPRESSION" ];then
                # 值为 yes/no 其他过滤
                pass="F"
                case "$REDIS_RDB_COMPRESSION" in
                    "yes")
                        pass="T"
                    ;;
                    "no")
                        pass="T"
                    ;;
                    *)
                        pass="F"
                    ;;
                esac
                if [ "$pass" = "T" ];then
                    echo  "rdbcompression ${REDIS_RDB_COMPRESSION}" >> "$CONFIG"
                fi

            fi

            # 是否开启appendonlylog yes or no
            file_env 'REDIS_APPEND_ONLY'
            if [ -n "$REDIS_APPEND_ONLY" ];then
                # 值为 yes/no 其他过滤
                pass="F"
                case "$REDIS_APPEND_ONLY" in
                    "yes")
                        pass="T"
                    ;;
                    "no")
                        pass="T"
                    ;;
                    *)
                        pass="F"
                    ;;
                esac
                if [ "$pass" = "T" ];then
                    echo  "appendonly $REDIS_APPEND_ONLY" >> "$CONFIG"
                fi
            fi

            #  appendonlylog如何同步到磁盘
            file_env 'REDIS_APPEND_FSYNC'
            if [ -n "$REDIS_APPEND_FSYNC" ];then
                 # 值为 always/everysec/no 其他过滤
                pass="F"
                case "$REDIS_APPEND_FSYNC" in
                    "always")
                        pass="T"
                    ;;
                    "everysec")
                        pass="T"
                    ;;
                    "no")
                        pass="T"
                    ;;
                    *)
                        pass="F"
                    ;;
                esac
                if [ "$pass" = "T" ];then
                    echo  "appendfsync $REDIS_APPEND_FSYNC" >> "$CONFIG"
                else
                    echo  "appendfsync value must be always/everysec/no."
                fi
            fi

            #  可使用的最大内存
            file_env 'REDIS_MAXMEMORY'
            if [ -n "$REDIS_MAXMEMORY" ];then
                # 大于等于0的数字 kb 为单位
                if grep '^[[:digit:]]*$' <<< "$REDIS_MAXMEMORY";then
                    if [ $REDIS_MAXMEMORY -ge 0 ]; then
                        echo  "maxmemory ${REDIS_MAXMEMORY}k" >> "$CONFIG"
                    fi
                else
                    echo "maxmemory value is not a number."
                fi
            fi

            # REDIS_MAXMEMORY-POLICY    内存不足时,数据清除策略
            file_env 'REDIS_MAXMEMORY_POLICY'
            if [ -n "$REDIS_MAXMEMORY_POLICY" ];then
                 # 值为 # volatile-lru / allkeys-lru / volatile-random / allkeys-random / volatile-ttl /  noeviction
                 # 其他过滤
                pass="F"
                case "$REDIS_MAXMEMORY_POLICY" in
                    "volatile-lru")
                        pass="T"
                    ;;
                    "allkeys-lru")
                        pass="T"
                    ;;
                    "volatile-random")
                        pass="T"
                    ;;
                    "allkeys-random")
                        pass="T"
                    ;;
                    "volatile-ttl")
                        pass="T"
                    ;;
                    "noeviction")
                        pass="T"
                    ;;
                    *)
                        pass="F"
                    ;;
                esac
                if [ "$pass" = "T" ];then
                    echo  "maxmemory-policy $REDIS_MAXMEMORY_POLICY" >> "$CONFIG"
                fi
            fi

            file_env 'REDIS_PASSWORD'
            if [ -n "$REDIS_PASSWORD" ];then
                echo  "requirepass $REDIS_PASSWORD" >> "$CONFIG"
            fi

            # ========= 比较特殊的两个配置 =============
            file_env 'REDIS_MIN_SLAVES_TO_WRITE'
            if [ -n "$REDIS_MIN_SLAVES_TO_WRITE" ];then
                # 大于等于0的数字
                if grep '^[[:digit:]]*$' <<< "$REDIS_MIN_SLAVES_TO_WRITE";then
                    if [ $REDIS_MIN_SLAVES_TO_WRITE -gt 0 ]; then
                        echo  "min-slaves-to-write $REDIS_MIN_SLAVES_TO_WRITE" >> "$CONFIG"
                    fi
                else
                    echo "min-slaves-to-write value is not a number."
                fi
            fi
            file_env 'REDIS_MIN_SLAVES_MAX_LAG'
            if [ -n "$REDIS_MIN_SLAVES_MAX_LAG" ];then
                # 大于等于0的数字
                if grep '^[[:digit:]]*$' <<< "$REDIS_MIN_SLAVES_MAX_LAG";then
                    if [ $REDIS_MIN_SLAVES_MAX_LAG -gt 0 ]; then
                        echo  "min-slaves-max-lag $REDIS_MIN_SLAVES_MAX_LAG" >> "$CONFIG"
                    fi
                else
                    echo "min-slaves-max-lag value is not a number."
                fi
            fi

        fi
    fi
	# add redis config end

	exec gosu redis "$0" "$@"

fi
exec "$@"
