#!/bin/bash
cd .
cd ./redis-node/
docker build -t wind634/redis:ha .
cd ..
cd ./redis-sentinel/
docker build -t wind634/redis-sentinel:ha  .
cd ..
cd ./haproxy/
docker build -t wind634/haproxy-redis:ha  .

#docker push wind634/haproxy-redis
#docker push wind634/redis
#docker push wind634/redis-sentinel
