#Docker commandos to start everything

docker run -d --hostname my-rabbit --name some-rabbit -p 8050:15672 -p 5672:5672 rabbitmq:3-management