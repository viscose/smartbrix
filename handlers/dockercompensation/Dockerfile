FROM ubuntu:14.04
MAINTAINER Johannes M. Schleicher <schleicher@dsg.tuwien.ac.at>

# Install packages for building ruby
RUN apt-get update
RUN apt-get install -y --force-yes build-essential wget git
RUN apt-get install -y --force-yes zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev
RUN apt-get clean

RUN wget -P /root/src http://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.2.tar.gz
RUN cd /root/src; tar xvf ruby-2.2.2.tar.gz
RUN cd /root/src/ruby-2.2.2; ./configure; make install

RUN gem update --system
RUN gem install bundler


# Install Curl 
RUN apt-get update
RUN apt-get install -y --force-yes curl
RUN apt-get clean
# # SqLite
# RUN apt-get -y install sqlite3 libsqlite3-dev

# Installing docker binary
ENV DOCKER_BUCKET get.docker.com
ENV DOCKER_VERSION 1.9.0
ENV DOCKER_SHA256 5d46455aac507e231fd2a558459779f1994f7151d6cb027efabfa36f568cf017

RUN curl -fSL "https://${DOCKER_BUCKET}/builds/Linux/x86_64/docker-$DOCKER_VERSION" -o /usr/local/bin/docker \
	&& echo "${DOCKER_SHA256}  /usr/local/bin/docker" | sha256sum -c - \
	&& chmod +x /usr/local/bin/docker


COPY Gemfile* /tmp/
WORKDIR /tmp
RUN bundle install

# Add assets
ADD ./ /dockercompensation
WORKDIR /dockercompensation

# RUN bundle install
#
ADD docker_start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

# EXPOSE 8000


ENTRYPOINT ["/opt/start.sh"]
# CMD ["/usr/local/bin/foreman","start","-d","/root/sinatra"]