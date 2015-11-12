#!/bin/bash
#
# Boot CoreOS Cluster
#
# Usage: boot-coreoscluster.sh

set -e

token=$(curl https://discovery.etcd.io/new)

user_data_file=$HOME/.cache/nova-default-user-data
num_instances=3

for i in $(seq 1 $num_instances); do
  echo "${token}"
  cat >${user_data_file}_$i <<EOF
#cloud-config
coreos:
  etcd:
    # generate a new token for each unique cluster from https://discovery.etcd.io/new
    # WARNING: replace each time you 'vagrant destroy'
    discovery: ${token}
    addr: \$private_ipv4:4001
    peer-addr: \$private_ipv4:7001
  fleet:
    public-ip: \$private_ipv4
    metadata: provider=$i
  units:
    - name: etcd.service
      command: start
    - name: fleet.service
      command: start
    - name: docker-tcp.socket
      command: start
      enable: true
      content: |
        [Unit]
        Description=Docker Socket for the API

        [Socket]
        ListenStream=2375
        Service=docker.service
        BindIPv6Only=both

        [Install]
        WantedBy=sockets.target

EOF
done

image_string=647.0.0
ip_string=$2

image_id=$(
  nova image-list|
  grep $image_string|
  head -1|
  awk 'BEGIN { FS="[ \t]*[|][ \t]*" } ; {print $2}'
)

if [ "$image_id" = "" ]; then
  echo "Could not find image matching '$image_string'!"
  exit 3
fi

image_name=$(
  nova image-show $image_id|
  grep "| name"|
  awk 'BEGIN { FS="[ \t]*[|][ \t]*" } ; {print $3}'
)
echo "Found image '${image_name}'..."

instance_name=smartbrix-instance-$(date +"%s")

for i in $(seq 1 $num_instances); do
  echo "Starting instance... $i"
  nova boot \
    --image $image_id \
    --flavor m1.small \
    --key_name dsg-cloud \
    --user-data ${user_data_file}_$i \
    ${instance_name}_$i
done


if [ $? -ne 0 ]; then
  echo "Instance failed to start."
  exit 4
fi

echo "Instances started."