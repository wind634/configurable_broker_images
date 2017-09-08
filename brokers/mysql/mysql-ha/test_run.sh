#!/bin/bash

# 此脚本测试docker-compose.yml编排的mysql服务是否可用

appname="wangjiang"

# 要替换的参数有
# appname  app名称
# PASSWORD  通信密码
# REDIS_MAXMEMORY   最大内存
COMPOSE_PATH="./docker-compose.yml"
TMP_COMPOSE_PATH="./temp_docker-compose.yml"

# 替换的变量
MACHINE1_LABLE="label1"
mysql_root_user="root"
mysql_user_pass="123456"
default_db="wangjiang"

MYSQL_MAX_CONNECTIONS="2222"
MYSQL_QUERY_CACHE_SIZE="10000"
MYSQL_CONNECT_TIMEOUT="222"
MYSQL_WAIT_TIMEOUT="222000"

MACHINE2_LABLE="label2"

VOLUMESIZE="100000"


if [  -f "$TMP_COMPOSE_PATH" ]; then
   rm "$TMP_COMPOSE_PATH"
fi

cp "$COMPOSE_PATH" "$TMP_COMPOSE_PATH"

sedCmd="s/{{MACHINE1_LABLE}}/${MACHINE1_LABLE}/g"
sed -i "$sedCmd" $TMP_COMPOSE_PATH

sedCmd="s/{{mysql_root_user}}/${mysql_root_user}/g"
sed -i "$sedCmd" $TMP_COMPOSE_PATH

sedCmd="s/{{mysql_user_pass}}/${mysql_user_pass}/g"
sed -i "$sedCmd" $TMP_COMPOSE_PATH

sedCmd="s/{{default_db}}/${default_db}/g"
sed -i "$sedCmd" $TMP_COMPOSE_PATH

sedCmd="s/{{MYSQL_MAX_CONNECTIONS}}/${MYSQL_MAX_CONNECTIONS}/g"
sed -i "$sedCmd" $TMP_COMPOSE_PATH

sedCmd="s/{{MYSQL_QUERY_CACHE_SIZE}}/${MYSQL_QUERY_CACHE_SIZE}/g"
sed -i "$sedCmd" $TMP_COMPOSE_PATH

sedCmd="s/{{MYSQL_CONNECT_TIMEOUT}}/${MYSQL_CONNECT_TIMEOUT}/g"
sed -i "$sedCmd" $TMP_COMPOSE_PATH

sedCmd="s/{{MYSQL_WAIT_TIMEOUT}}/${MYSQL_WAIT_TIMEOUT}/g"
sed -i "$sedCmd" $TMP_COMPOSE_PATH

sedCmd="s/{{MACHINE2_LABLE}}/${MACHINE2_LABLE}/g"
sed -i "$sedCmd" $TMP_COMPOSE_PATH

sedCmd="s/{{VOLUMESIZE}}/${VOLUMESIZE}/g"
sed -i "$sedCmd" $TMP_COMPOSE_PATH

#docker-compose  -f "${TMP_COMPOSE_PATH}" up -d
# swarm模式
#docker swarm init
docker stack deploy -c "$TMP_COMPOSE_PATH" "$appname"