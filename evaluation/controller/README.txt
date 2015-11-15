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
  --publish=8080:8080 \
  --detach=true \
  --name=cadvisor \
  google/cadvisor:latest


# Cleanups 

docker rm -v $(docker ps -a -q -f status=exited)

# Delete all containers
docker rm $(docker ps -a -q)
# Delete all images
docker rmi $(docker images -q)