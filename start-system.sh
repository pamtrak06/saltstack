#!/bin/bash
docker-compose -p test up -d --build --scale salt_minion=3
