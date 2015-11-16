#Docker commandos to start everything

docker run -d --hostname my-rabbit --name some-rabbit -p 8050:15672 -p 5672:5672 rabbitmq:3-management


docker run -d -p 27017:27017 --name mongodb -v /data/db:/data/db mongo:3.0

docker run -d -p 8080:8080 --name restheart --link mongodb:mongodb softinstigate/restheart

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

# Grafana

docker run -d -p 3000:3000 -e INFLUXDB_HOST=localhost -e INFLUXDB_PORT=8086 -e INFLUXDB_NAME=cadvisor -e INFLUXDB_USER=root -e INFLUXDB_PASS=root --link influxsrv:influxsrv --name grafana grafana/grafana

# Cleanups 

docker rm -v $(docker ps -a -q -f status=exited)

docker rmi $(docker images -f "dangling=true" -q)

# Delete all containers
docker rm $(docker ps -a -q)
# Delete all images
docker rmi $(docker images -q)



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