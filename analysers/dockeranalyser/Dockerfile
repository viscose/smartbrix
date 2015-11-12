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

# SqLite
RUN apt-get -y install sqlite3 libsqlite3-dev

COPY Gemfile* /tmp/
WORKDIR /tmp
RUN bundle install

# Add assets
ADD ./ /dockeranalyser
WORKDIR /dockeranalyser

# RUN bundle install
#
ADD docker_start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

EXPOSE 8000


ENTRYPOINT ["/opt/start.sh"]
# CMD ["/usr/local/bin/foreman","start","-d","/root/sinatra"]