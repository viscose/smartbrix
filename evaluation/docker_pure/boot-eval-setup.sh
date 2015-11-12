#!/bin/bash
#
# Boot CoreOS Cluster
#
# Usage: boot-coreoscluster.sh

set -e

docker_container_id=$(docker run -d -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/bin/docker -e "DBURL=128.128.128.128" -p 8000:8000 -t smartbrix/dockeranalyser)

echo "Instances started."