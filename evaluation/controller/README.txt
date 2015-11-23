#Docker commandos to start everything

docker run -d --hostname my-rabbit --name some-rabbit -p 8050:15672 -p 5672:5672 rabbitmq:3-management


docker run -d -p 27017:27017 --name mongodb -v /data/db:/data/db mongo:3.0

docker run -d -p 8080:8080 --name restheart --link mongodb:mongodb softinstigate/restheart

# Move to emph volume with docker 

echo 'DOCKER_OPTS="-g /mnt"' |sudo tee -a /etc/default/docker
sudo service docker restart

# Dockeranalyser

docker run -d -v /var/run/docker.sock:/var/run/docker.sock -v /usr/local/bin/docker:/bin/docker -e SB_CVEHUB=10.99.0.43:8020 -e SB_DBURL=10.99.0.43:8080 -e SB_MQ=10.99.0.43 -t smartbrix/dockeranalyser

# Cadivor

docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:rw \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --publish=8010:8080 \
  --detach=true \
  --name=cadvisor \
  google/cadvisor:latest
  
# Influx

docker run -d -p 8083:8083 -p 8086:8086 --expose 8090 --expose 8099 --name influxsrv tutum/influxdb:0.8.8
  
# Cadvisor with Influx link

docker run --volume=/:/rootfs:ro --volume=/var/run:/var/run:rw --volume=/sys:/sys:ro --volume=/var/lib/docker/:/var/lib/docker:ro --publish=8010:8080 --detach=true --link influxsrv:influxsrv --name=cadvisor google/cadvisor:latest -storage_driver=influxdb -storage_driver_db=cadvisor -storage_driver_host=influxsrv:8086

# Cadvisor with remote Influx

docker run --volume=/:/rootfs:ro --volume=/var/run:/var/run:rw --volume=/sys:/sys:ro --volume=/var/lib/docker/:/var/lib/docker:ro --publish=8010:8080 --detach=true --name=cadvisor google/cadvisor:latest -storage_driver=influxdb -storage_driver_db=cadvisor -storage_driver_host=10.99.0.43:8086

# Grafana

docker run -d -p 3000:3000 -e INFLUXDB_HOST=localhost -e INFLUXDB_PORT=8086 -e INFLUXDB_NAME=cadvisor -e INFLUXDB_USER=root -e INFLUXDB_PASS=root --link influxsrv:influxsrv --name grafana grafana/grafana

# Cleanups 

docker rm -v $(docker ps -a -q -f status=exited)

docker rmi $(docker images -f "dangling=true" -q)

# Delete all containers
docker rm $(docker ps -a -q)
# Delete all images
docker rmi $(docker images -q)

# Clean up exploding image handles

sudo ls /var/lib/docker/tmp

sudo rm /var/lib/docker/tmp/*

--- General creation commands ---

docker-machine create --driver generic\
  --generic-ip-address 128.130.172.213\
  --generic-ssh-user ubuntu\
  --generic-ssh-key $HOME/.ssh/dsg-cloud.pem\
  smartbrix-controller
  
  docker-machine create --driver generic\
    --generic-ip-address 128.130.172.190\
    --generic-ssh-user ubuntu\
    --generic-ssh-key $HOME/.ssh/dsg-cloud.pem\
    smartbrix-eval-1
    
  docker-machine create --driver generic\
    --generic-ip-address 128.130.172.196\
    --generic-ssh-user ubuntu\
    --generic-ssh-key $HOME/.ssh/dsg-cloud.pem\
    smartbrix-eval-2





### QUERIES

{ vulnerabilities: {$exists: true, $gt: {$size: 0}} }

# Official
{ image_name: {$regex: '^[^/]*$'} }

# Not official
{ image_name: {$regex: '.+/.+'} }


#INFLUXDB

curl -G 'http://128.130.172.213:8086/db/cadvisor/series?u=root&p=root&pretty=true' --data-urlencode "q=select * from stats where time > '2015-11-22 01:00:01.232'" > eval_run_500

curl -G 'http://128.130.172.213:8086/db/cadvisor/series?u=root&p=root&pretty=true' --data-urlencode "q=select * from stats where time > '2015-11-22 01:00:01.232'" > eval_run_500

