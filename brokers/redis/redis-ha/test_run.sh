#!/bin/bash

# 此脚本测试docker-compose.yml编排的redis服务是否可用

# 要替换的参数有
# appname  app名称
# PASSWORD  通信密码
# REDIS_MAXMEMORY   最大内存
COMPOSE_PATH="./docker-compose.yml"
TMP_COMPOSE_PATH="./temp_docker-compose.yml"

appname="wind_test"
PASSWORD="123456"
# 100m
REDIS_MAXMEMORY="102400"

if [  -f "$TMP_COMPOSE_PATH" ]; then
   rm "$TMP_COMPOSE_PATH"
fi

cp "$COMPOSE_PATH" "$TMP_COMPOSE_PATH"

sedCmd="s/{{appname}}/${appname}/g"
sed -i "$sedCmd" $TMP_COMPOSE_PATH

sedCmd="s/{{PASSWORD}}/${PASSWORD}/g"
sed -i "$sedCmd" $TMP_COMPOSE_PATH

sedCmd="s/{{REDIS_MAXMEMORY}}/${REDIS_MAXMEMORY}/g"
sed -i "$sedCmd" $TMP_COMPOSE_PATH

#docker-compose up -d
# swarm模式
#docker swarm init
#docker stack deploy -c docker-compose.yml redis_ha_test