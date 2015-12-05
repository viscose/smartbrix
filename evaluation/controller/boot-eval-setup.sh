#!/bin/bash
#
# Boot CoreOS Cluster
#
# Usage: boot-coreoscluster.sh

set -e

#Local
docker_container_id=$(docker run -d -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/bin/docker -e SB_CVEHUB=192.168.99.100:8020 -e SB_DBURL=192.168.99.100:8080 -e SB_MQ=192.168.99.100 -t smartbrix/dockeranalyser)


#Remote Analyser
docker_container_id=$(docker run -d -v /var/run/docker.sock:/var/run/docker.sock -v /usr/local/bin/docker:/bin/docker -e SB_CVEHUB=10.99.0.43:3000 -e SB_DBURL=10.99.0.43:8080  -e SB_DBCOLL=vulnerabilities -e SB_MQ=10.99.0.43 -t smartbrix/dockeranalyser)



#Remote Compensation
docker_container_id=$(docker run -d -v /var/run/docker.sock:/var/run/docker.sock -v /usr/local/bin/docker:/bin/docker -e SB_CVEHUB=10.99.0.43:8020 -e SB_C_STRAT=image -e SB_DBURL=10.99.0.43:8080 -e SB_MQ=10.99.0.43 -t smartbrix/dockercompensation)



# Create databases / collection
http PUT admin:admin@128.130.172.213:8080/analytics desc='Smartbrix Evaluation'
http PUT admin:admin@128.130.172.213:8080/analytics/vulnerabilities desc='Vulnerabilites'

docker_id=$(docker run -d -p 8020:8020 -t smartbrix/cvehub))

echo "Instances started."