#!/bin/bash
#
# Boot Dockerswarm
#
# Usage: boot-swarm.sh

set -e

token=$(curl https://discovery.etcd.io/new)

user_data_file=$HOME/.cache/nova-default-user-data
num_instances=3

ip_1=128.130.172.178
ip_2=128.130.172.190
ip_3=128.130.172.213

swarm_token="$(docker run swarm create)"

echo "Generated swarm token was: ${swarm_token}"

# Master
docker-machine create --driver generic\
  --generic-ip-address ${ip_1}\
  --generic-ssh-user ubuntu\
  --generic-ssh-key $HOME/.ssh/dsg-cloud.pem\
  --swarm \
  --swarm-master \
  --swarm-discovery token://${swarm_token} \
  swarm-master


# Node
docker-machine create --driver generic\
  --generic-ip-address ${ip_2}\
  --generic-ssh-user ubuntu\
  --generic-ssh-key $HOME/.ssh/dsg-cloud.pem\
  --swarm \
  --swarm-discovery token://${swarm_token} \
  swarm-agent-01

# Node
docker-machine create --driver generic\
  --generic-ip-address ${ip_3}\
  --generic-ssh-user ubuntu\
  --generic-ssh-key $HOME/.ssh/dsg-cloud.pem\
  --swarm \
  --swarm-discovery token://${swarm_token} \
  swarm-agent-02


echo "Swarm started."