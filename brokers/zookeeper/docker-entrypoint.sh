#!/bin/bash
#用户可以进行配置的环境变量
# ZOO_TICK_TIME   server端通信心跳间隔时间, 以毫秒为单位
# ZOO_INIT_LIMIT  集群中的follower和leader初始连接时能容忍的最多心跳数（tickTime的数量）
# ZOO_SYNC_LIMIT  集群中的follower服务器与leader服务器之间请求和应答之间能容忍的最多心跳数（tickTime的数量）
# ZOO_SERVERS  集群的server配置 server.1=zoo1:2888:3888 server.2=zoo2:2888:3888 server.3=zoo3:2888:3888

# === 还有一块是zookeeper的jvm的配置
# ZOO_JVM_XMS  初始堆大小
# ZOO_JVM_XMX  最大堆大小
# ZOO_JVM_XSS  每个线程的栈大小

# === 配置文件类型 ===
# ZOO_CONF_FILE_*  该类型配置会逐行写入zoo.cfg配置文件中  ZOO_CONF_FILE_0  ZOO_CONF_FILE_1 依次类推
# ZOO_JVM_CONF_FILE_*   该类型配置会逐行写入java.env配置文件中  ZOO_JVM_CONF_FILE_0 ZOO_JVM_CONF_FILE_1 依次类推


# Allow the container to be started with `--user`
if [ "$1" = 'zkServer.sh' -a "$(id -u)" = '0' ]; then
    chown -R "$ZOO_USER" "$ZOO_DATA_DIR" "$ZOO_DATA_LOG_DIR"
    exec su-exec "$ZOO_USER" "$0" "$@"
fi


USE_ZOO_CONF_FILE="false"
USE_ZOO_JVM_CONF_FILE="false"


zoo_env_array=()
zoo_jvm_env_array=()

# 配置文件形式
zoo_conf_file_array=()
zoo_jvm_conf_file_array=()


for LINE in `env`
do
    # 逐行读取  等号分割
    env_key=`echo $LINE | cut -d = -f 1`
    case $env_key in
        "ZOO_CONF_FILE_"*)
            # 只要该环节变量存在,说明是使用配置文件的形式
            USE_ZOO_CONF_FILE="true"
            zoo_conf_file_array+=($env_key)
        ;;

        "ZOO_JVM_CONF_FILE_"*)
            USE_ZOO_JVM_CONF_FILE="true"
            zoo_jvm_conf_file_array+=($env_key)
        ;;

        "ZOO_JVM_"*)
            zoo_jvm_env_array+=($env_key)
        ;;

        "ZOO_"*)
            zoo_env_array+=($env_key)
        ;;

        *)
            :
        ;;
    esac

done


# 自动生成配置文件如果不存在 zoo.cfg
if [ ! -f "$ZOO_CONF_DIR/zoo.cfg" ]; then
    CONFIG="$ZOO_CONF_DIR/zoo.cfg"
    if [ $USE_ZOO_CONF_FILE == "true" ];then
        # 以配置文件的方式写入
        # 读取每一行环境变量
        # 按照末尾序号进行排序
        len=${#zoo_conf_file_array[@]}
        for((i=0; i<$len; i++)){
          for((j=i+1; j<$len; j++)){
             num1=${zoo_conf_file_array[i]:14}
             num2=${zoo_conf_file_array[j]:14}
            if [[ ${num1} -gt ${num2} ]]
            then
              temp=${zoo_conf_file_array[i]}
              zoo_conf_file_array[i]=${zoo_conf_file_array[j]}
              zoo_conf_file_array[j]=$temp
            fi
          }
        }

        client_port_defined="F"
        data_dir_defined="F"
        data_log_dir_defined="F"
        zooservers=""
        # 重定向到配置文件路径
        for ((i=0;i<${#zoo_conf_file_array[@]};i++))
        do
            arg=${zoo_conf_file_array[$i]}
            var="$arg"
            val=${!var}
            # 每一行进行正则过滤，不符合格式则不写入
            checkedVal=`echo "$val" | grep -E '^(\s*#\s*(\S*\s*)*\s*)$|^(\s*\w+\s*=\s*\S+\s*)$|^(\s*(\w+.[1-9]+\s*\=\s*\w+\s*\:\s*[1-9]+\s*\:\s*[1-9]+\s*){1}\s*)$' `

            if [ -n "$checkedVal" ]; then
                grep_servers_val=`echo "$val" | grep -E '^(\s*(\w+.[1-9]+\s*\=\s*\w+\s*\:\s*[1-9]+\s*\:\s*[1-9]+\s*){1}\s*)$'`
                if [ -n "$grep_servers_val" ]; then
                    # 如果是个服务器配置
                    filted_val=`echo $val | sed s/[[:space:]]//g`
                    server_name=`echo $filted_val|cut -d ' ' -f 1 |cut -d = -f 2 |cut -d ':' -f 1`
                    zooservers+="$server_name "
                fi
                if [[ "$val" == *"clientPort"* ]];then
                    client_port_defined="T"
                fi
                if [[ "$val" == *"dataDir"* ]];then
                    data_dir_defined="T"
                fi
                if [[ "$val" == *"dataLogDir"* ]];then
                    data_log_dir_defined="T"
                fi

                echo "env_file_row ${arg}'s content..."${val}
                echo "$val" >> "$CONFIG"
            fi
        done

        # 默认配置处理（clientPort,dataDir和dataLogDir必须要配置不然无法启动）
        if [ "$client_port_defined" == "F" ];then
            echo "clientPort=$ZOO_PORT" >> "$CONFIG"
        fi
        if [ "$data_dir_defined" == "F" ];then
            echo "dataDir=$ZOO_DATA_DIR" >> "$CONFIG"
        fi
        if [ "$data_log_dir_defined" == "F" ];then
            echo "dataLogDir=$ZOO_DATA_LOG_DIR" >> "$CONFIG"
        fi

    else
        for ((i=0;i<${#zoo_env_array[@]};i++))
        do
            arg=${zoo_env_array[$i]}
            var="$arg"
            val=${!var}
            echo "get env ${arg}'s value..."${val}
            if [ -n "$val" ];then
                case $arg in
                    "ZOO_PORT")
                        if grep '^[[:digit:]]*$' <<< $val;then
                           # 判断端口号是否在1024~65535之间
                           if [ $val -gt 1024 -a $val -lt 65535 ]; then
                             echo "clientPort=$val" >> "$CONFIG"
                           fi
                        fi
                    ;;
                    "ZOO_DATA_DIR")
                        echo "dataDir=$val" >> "$CONFIG"
                    ;;
                    "ZOO_DATA_LOG_DIR")
                        echo "dataLogDir=$val" >> "$CONFIG"
                    ;;
                    "ZOO_TICK_TIME")
                        if grep '^[[:digit:]]*$' <<< "$val";then
                            # 正整数数值
                            if [ $val -gt 0 ]; then
                                echo "tickTime=$val" >> "$CONFIG"
                            fi
                        fi
                    ;;
                    "ZOO_INIT_LIMIT")
                        if grep '^[[:digit:]]*$' <<< "$val";then
                            # 正整数数值
                            if [ $val -gt 0 ]; then
                                echo "initLimit=$val" >> "$CONFIG"
                            fi
                        fi
                    ;;
                    "ZOO_SYNC_LIMIT")
                        if grep '^[[:digit:]]*$' <<< "$val";then
                            # 正整数数值
                            if [ $val -gt 0 ]; then
                                echo "syncLimit=$val" >> "$CONFIG"
                            fi
                        fi
                    ;;
                    "ZOO_SERVERS")
                        # servers config
                        # 去空格
                        val=`echo $val | sed s/[[:space:]]//g`
                        checkedVal=`echo "$val" | grep -E '^(\w+.[1-9]+\=\w+\:[1-9]+\:[1-9]+)+$|^(\w+.[1-9]+\=\w+\:[1-9]+\:[1-9]+\,)+(\w+.[1-9]+\=\w+\:[1-9]+\:[1-9]+){1}$' `
                        if [ -n "$checkedVal" ];then
                            # ,号替换成空格
                            zooservers=`echo ${val//,/ }`
                            if [[ $? -eq 0 ]]; then
                                for server in $zooservers; do
                                    echo "$server" >> "$CONFIG"
                                done
                            fi
                        else
                          echo "the ZOO_SERVERS args format wrong..."
                        fi
                    ;;
                    *)
                        catalinaStr+=" "
                    ;;
                esac
            fi
        done

    fi
fi

java_flags=""
# jvm配置 conf/java.env
if [ ! -f "$ZOO_CONF_DIR/java.env" ]; then
    JAVA_ENV="$ZOO_CONF_DIR/java.env"
     if [ $USE_ZOO_JVM_CONF_FILE == "true" ];then
        # 以配置文件的方式写入
        # 读取每一行环境变量
        # 按照末尾序号进行排序
        len=${#zoo_jvm_conf_file_array[@]}
        for((i=0; i<$len; i++)){
          for((j=i+1; j<$len; j++)){
             num1=${zoo_jvm_conf_file_array[i]:18}
             num2=${zoo_jvm_conf_file_array[j]:18}
            if [[ ${num1} -gt ${num2} ]]
            then
              temp=${zoo_jvm_conf_file_array[i]}
              zoo_jvm_conf_file_array[i]=${zoo_jvm_conf_file_array[j]}
              zoo_jvm_conf_file_array[j]=$temp
            fi
          }
        }

        # 重定向到配置文件路径
        for ((i=0;i<${#zoo_jvm_conf_file_array[@]};i++))
        do
            arg=${zoo_jvm_conf_file_array[$i]}
            var="$arg"
            val=${!var}
            # 每一行进行正则过滤，不符合格式则不写入
            checkedVal=`echo "$val" | grep -E '^(\s*#\s*(\S*\s*)*\s*)|(\s*\w+\s*=\s*\w+\s*)$' `
            if [ -n "$checkedVal" ]; then
                echo "env_file_row ${arg}'s content..."${val}
                echo "$val" >> "$JAVA_ENV"
            fi
        done

    else
        for ((i=0;i<${#zoo_jvm_env_array[@]};i++))
        do
            arg=${zoo_jvm_env_array[$i]}
            var="$arg"
            val=${!var}
            echo "get env ${arg}'s value..."${val}

            if [ -n "$val" ];then
                case $arg in
                    "ZOO_JVM_XMS")
                        if grep '^[[:digit:]]*$' <<< "$val";then
                            # 正整数数值
                            if [ $val -gt 0 ]; then
                                if [ $val -lt 65536 ]; then
                                    echo "the jvm xms is too small, must higher than 64m, then rejected..."
                                else
                                    java_flags+=" -Xms${val}k"
                                fi
                            fi
                        fi
                    ;;
                    "ZOO_JVM_XMX")
                        if grep '^[[:digit:]]*$' <<< "$val";then
                            # 正整数数值
                            if [ $val -gt 0 ]; then
                                if [ $val -lt 65536 ]; then
                                    echo "the jvm xmx is too small, must higher than 64m, then rejected..."
                                else
                                    java_flags+=" -Xmx${val}k"
                                fi
                            fi
                        fi
                    ;;
                    "ZOO_JVM_XSS")
                        if grep '^[[:digit:]]*$' <<< "$val";then
                            # 正整数数值
                            if [ $val -gt 0 ]; then
                                # 线程栈大小要大于228k
                                if [ $val -lt 228 ]; then
                                    echo "the jvm xss is too small ,then rejected..."
                                else
                                    java_flags+=" -Xss${val}k"
                                fi
                            fi
                        fi
                    ;;
                    *)
                        catalinaStr+=" "
                    ;;
                esac
            fi
        done

        if  [ -n "$java_flags" ];then
            java_flags+=" \$JVMFLAGS"
            echo "java_flags:"$java_flags
            echo "export JVMFLAGS=\"$java_flags\"" >> "$JAVA_ENV"
        fi
    fi
fi

# 配置文件结束后进行网络通信检查
if [ -n "$zooservers" ];then
    for zk_service in `echo $zooservers`
    do
        zk_host_name=`echo $zk_service|cut -d ' ' -f 1 |cut -d = -f 2 |cut -d ':' -f 1`
        echo "wait $zk_host_name network is ok"
        while true
        do
            ping -c 1 $zk_host_name >/dev/null 2>&1 &&  break  || ( echo -e "."; sleep 1s )
        done
    done
fi


# 如果myid文件不存在, 自动重写myid文件
if [ ! -f "$ZOO_DATA_DIR/myid" ]; then
   echo "${ZOO_MY_ID:-1}" > "$ZOO_DATA_DIR/myid"
fi

exec "$@"