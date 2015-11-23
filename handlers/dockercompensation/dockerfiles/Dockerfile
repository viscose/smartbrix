FROM ubuntu
CMD ["/bin/bash"]
RUN groupadd -r mongodb && useradd -r -g mongodb mongodb
RUN apt-get update 	&& apt-get install -y --no-install-recommends 		ca-certificates curl 		numactl 	&& rm -rf /var/lib/apt/lists/*
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.6/gosu-$(dpkg --print-architecture)" 	&& curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.6/gosu-$(dpkg --print-architecture).asc" 	&& gpg --verify /usr/local/bin/gosu.asc 	&& rm /usr/local/bin/gosu.asc 	&& chmod +x /usr/local/bin/gosu
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 492EAFE8CD016A07919F1D2B9ECBEC467F0CEB10
ENV MONGO_MAJOR=3.0
ENV MONGO_VERSION=3.0.7
RUN echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/$MONGO_MAJOR main" > /etc/apt/sources.list.d/mongodb-org.list
RUN set -x 	&& apt-get update 	&& apt-get install -y 		mongodb-org=$MONGO_VERSION 		mongodb-org-server=$MONGO_VERSION 		mongodb-org-shell=$MONGO_VERSION 		mongodb-org-mongos=$MONGO_VERSION 		mongodb-org-tools=$MONGO_VERSION 	&& rm -rf /var/lib/apt/lists/* 	&& rm -rf /var/lib/mongodb 	&& mv /etc/mongod.conf /etc/mongod.conf.orig
RUN mkdir -p /data/db && chown -R mongodb:mongodb /data/db
VOLUME [/data/db]
COPY file:50ff82dffc60abfb55782f6a329b2ec2b9d2c20009f3be01968dcd4124c68df1 in /entrypoint.sh
ENTRYPOINT &{["/entrypoint.sh"]}
EXPOSE 27017/tcp
CMD ["mongod"]
