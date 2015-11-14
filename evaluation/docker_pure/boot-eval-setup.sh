#!/bin/bash
#
# Boot CoreOS Cluster
#
# Usage: boot-coreoscluster.sh

set -e

docker_container_id=$(docker run -d -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/bin/docker -e SB_CVEHUB=192.168.99.100:8020 -e SB_DBURL=192.168.99.100:8080 -e SB_MQ=192.168.99.100 -p 8000:8000 -t smartbrix/dockeranalyser)


# Create databases / collection
http PUT admin:admin@128.130.172.213:8080/analytics desc='Smartbrix Evaluation'
http PUT admin:admin@192.168.99.100:8080/analytics/vulnerabilities desc='Vulnerabilites'

echo "Instances started."