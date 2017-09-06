#!/bin/bash

# 此脚本测试docker-compose.yml编排的redis服务是否可用

# 要替换的参数有
# appname  app名称
# PASSWORD  通信密码
# REDIS_MAXMEMORY   最大内存
COMPOSE_PATH="./docker-compose.yml"

appname="wind_test"
PASSWORD="123456"
# 100m
REDIS_MAXMEMORY="102400"

if [  -f "$COMPOSE_PATH" ]; then
   rm "./docker-compose.yml"
fi

cp "./docker-compose_template.yml" "./docker-compose.yml"

sedCmd="s/{{appname}}/${appname}/g"
sed -i "$sedCmd" ./docker-compose.yml

sedCmd="s/{{PASSWORD}}/${PASSWORD}/g"
sed -i "$sedCmd" ./docker-compose.yml

sedCmd="s/{{REDIS_MAXMEMORY}}/${REDIS_MAXMEMORY}/g"
sed -i "$sedCmd" ./docker-compose.yml

docker-compose up -d