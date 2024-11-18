#!/bin/bash
source config.sh
docker-compose -p $CONFIG_COMPOSE_PREFIX $@
