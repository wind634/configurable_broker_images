#!/bin/bash


docker-compose up -d
# swarm模式下不成功
#docker stack deploy -c ./docker-compose.yml "zoo_test"