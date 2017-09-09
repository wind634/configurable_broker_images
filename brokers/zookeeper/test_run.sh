#!/bin/bash


docker-compose up -d
# swarm模式下总是连不上
#docker stack deploy -c ./docker-compose.yml "zoo_test"