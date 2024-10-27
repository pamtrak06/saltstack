#!/bin/bash
source config.sh
docker-compose -p $CONFIG_MINION_PREFIX up -d --build --scale salt_minion=$CONFIG_NUM_MINIONS
