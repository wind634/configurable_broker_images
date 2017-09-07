#!/bin/bash
# sentinel节点的配置方式
# sentinel节点可以配置多个master,目前只配置一个,*号统一取0
# REDIS_SENTINEL_MASTER_NAME_* 主机名称
# REDIS_SENTINEL_MASTER_HOST_*   ip
# REDIS_SENTINEL_MASTER_PORT_*   port
# REDIS_SENTINEL_MASTER_QUORUM_*   quorum
# REDIS_SENTINEL_DOWN_AFTER_MILLISECONDS_*  失效时间, 单位是毫秒，默认为30秒
# REDIS_SENTINEL_FAILOVER_TIMEOUT_*  failover超时时间
# REDIS_SENTINEL_PARALLEL_SYNCS_* 主备切换时最多可以有多少个slave同时对新的master同步
# REDIS_SENTINEL_PASSWORD_* 主备切换时最多可以有多少个slave同时对新的master同步

# 配置文件在/usr/local/etc/redis/sentinel.conf 路径下

# REDIS_SENTINEL_CONF_FILE_*

# set -e

# config file path
CONFIG_DIR="/usr/local/etc/redis"
CONFIG="$CONFIG_DIR/sentinel.conf"

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
	set -- redis-sentinel "$@"
fi

# allow the container to be started with `--user`
if [ "$1" = 'redis-sentinel' -a "$(id -u)" = '0' ]; then
	chown -R redis .

	# add redis config start
	master_name_array=()

    USE_REDIS_SENTINEL_CONF_FILE="false"
    redis_sentinel_conf_file_array=()

    for LINE in `env`
    do
        # 逐行读取  等号分割
        env_key=`echo $LINE | cut -d = -f 1`
        case $env_key in
            "REDIS_SENTINEL_CONF_FILE_"*)
                # 只要该环节变量存在,说明是使用配置文件的形式
                USE_REDIS_SENTINEL_CONF_FILE="true"
                redis_sentinel_conf_file_array+=($env_key)
            ;;
            "REDIS_SENTINEL_MASTER_NAME_"*)
                master_name_array+=($env_key)
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
        chown -R redis "$CONFIG_DIR"
        if [ $USE_REDIS_SENTINEL_CONF_FILE == "true" ];then
            # 以配置文件的方式写入
            # 读取每一行环境变量
            # 按照末尾序号进行排序
            len=${#redis_sentinel_conf_file_array[@]}
            for((i=0; i<$len; i++)){
              for((j=i+1; j<$len; j++)){
                 num1=${redis_sentinel_conf_file_array[i]:25}
                 num2=${redis_sentinel_conf_file_array[j]:25}
                 echo "num1"$num1
                 echo "num2"$num2
                if [[ ${num1} -gt ${num2} ]]
                then
                  temp=${redis_sentinel_conf_file_array[i]}
                  redis_sentinel_conf_file_array[i]=${redis_sentinel_conf_file_array[j]}
                  redis_sentinel_conf_file_array[j]=$temp
                fi
              }
            }

            # 重定向到配置文件路径
            for ((i=0;i<${#redis_sentinel_conf_file_array[@]};i++))
            do
                arg=${redis_sentinel_conf_file_array[$i]}
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
            # 以环境变量方式写入
            len=${#master_name_array[@]}
            # master name 必须，否则报错exit
            if [ $len == 0 ];then
                echo >&2 'error: REDIS_SENTINEL_MASTER_NAME env variable is must required.'
                exit 1
            fi

            for((i=0; i<len; i++))
            do
                file_env ${master_name_array[i]}
                master_name=${!master_name_array[i]}

                # 获取mastername对应下标的其他环境变量
                master_req=${master_name_array[i]:27}

                 # master ip
                key='REDIS_SENTINEL_MASTER_HOST_'${master_req}
                file_env key
                value=${!key}
                if [ -n "$value" ];then
                    master_host=$value
                fi
                master_host=${master_host:-'127.0.0.1'}

                # master port
                key='REDIS_SENTINEL_MASTER_PORT_'${master_req}
                file_env key
                value=${!key}
                if [ -n "$value" ];then
                    if grep '^[[:digit:]]*$' <<< "$value";then
                        master_port=$value
                    fi
                fi
                master_port=${master_port:-'6379'}

                # master quorum
                key='REDIS_SENTINEL_MASTER_QUORUM_'${master_req}
                file_env key
                value=${!key}
                if [ -n "$value" ];then
                    if grep '^[[:digit:]]*$' <<< "$value";then
                        master_quorum=$value
                    fi
                fi
                master_quorum=${master_quorum:-'2'}

               echo  "sentinel monitor $master_name $master_host $master_port $master_quorum" >> "$CONFIG"

                # 失效时间
                key='REDIS_SENTINEL_DOWN_AFTER_MILLISECONDS_'${master_req}
                file_env key
                value=${!key}
                if [ -n "$value" ];then
                    # 大于等于0的数字
                    if grep '^[[:digit:]]*$' <<< "$value";then
                        if [ $value -gt 0 ]; then
                            echo  "sentinel down-after-milliseconds $master_name $value" >> "$CONFIG"
                        fi
                    else
                        echo "sentinel down-after-milliseconds value is not a number."
                    fi
                fi

                # 间隔时间
                key='REDIS_SENTINEL_FAILOVER_TIMEOUT_'${master_req}
                file_env key
                value=${!key}
                if [ -n "$value" ];then
                    # 大于等于0的数字
                    if grep '^[[:digit:]]*$' <<< "$value";then
                        if [ $value -gt 0 ]; then
                            echo  "sentinel failover-timeout $master_name $value" >> "$CONFIG"
                        fi
                    else
                        echo "sentinel failover-timeout value is not a number."
                    fi
                fi

                # 同步数量
                key='REDIS_SENTINEL_PARALLEL_SYNCS_'${master_req}
                file_env key
                value=${!key}
                if [ -n "$value" ];then
                    # 大于等于0的数字
                    if grep '^[[:digit:]]*$' <<< "$value";then
                        if [ $value -gt 0 ]; then
                            echo  "sentinel parallel-syncs $master_name $value" >> "$CONFIG"
                        fi
                    else
                        echo "sentinel parallel-syncs value is not a number."
                    fi
                fi

                # 认证密码
                key='REDIS_SENTINEL_PASSWORD_'${master_req}
                file_env key
                value=${!key}
                if [ -n "$value" ];then
                    echo  "sentinel auth-pass $master_name $value" >> "$CONFIG"
                fi

                echo "sentinel config-epoch $master_name  0" >> "$CONFIG"
                echo "sentinel leader-epoch $master_name  1" >> "$CONFIG"

            done

        fi
    fi
	# add redis config end

	exec gosu redis "$0" "$@"
fi


exec "$@"