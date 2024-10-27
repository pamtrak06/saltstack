#!/bin/bash
source config.sh
docker-compose -p $CONFIG_MINION_PREFIX exec salt_master bash
