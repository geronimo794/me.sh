#!/bin/bash

CONTAINER_NAME="xxxx"

sudo docker exec -i $CONTAINER_NAME mysqldump -u root -p xxx > xxx.sql
