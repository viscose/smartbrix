#!/bin/bash
#
# Boot CoreOS Cluster
#
# Usage: boot-coreoscluster.sh

set -e

docker_container_id=$(docker run -d -v /var/run/docker.sock:/var/run/docker.sock -p 8000:8000 smartbrix/dockeranalyser)



# token=$(curl https://discovery.etcd.io/new)
#
# user_data_file=$HOME/.cache/nova-default-user-data
# num_instances=3
#
# ip_string=$2
#
# # Ubuntu 14.04
# image_id=be6ae07b-7deb-4926-bfd7-b11afe228d6a
#
# image_name=$(
#   nova image-show $image_id|
#   grep "| name"|
#   awk 'BEGIN { FS="[ \t]*[|][ \t]*" } ; {print $3}'
# )
# echo "Found image '${image_name}'..."
#
# instance_name=instance-$(date +"%s")
#
# for i in $(seq 1 $num_instances); do
#   echo "Starting instance... $i"
#   nova boot \
#     --image $image_id \
#     --flavor m1.small \
#     --key_name dsg-cloud \
#     ${instance_name}_$i
# done
#
#
# if [ $? -ne 0 ]; then
#   echo "Instance failed to start."
#   exit 4
# fi

echo "Instances started."