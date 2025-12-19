#!/bin/bash
################################
# Open firewall ports:         #
# TCP: 8080, 10051, 10050      #
# UDP: 162                     #
################################

set -e

# Create directories for files and libs
mkdir -p ./zabbix/tmp

# Directories permissions
chmod 666 ./zabbix/tmp

# Compose docker environment
docker compose -f ./zabbix-docker.yml up -d

# Verify docker processes
watch -n3 "docker ps"