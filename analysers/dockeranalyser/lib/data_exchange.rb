require 'bunny'

class DataExchange
    
  def initialize(topic)
    
    endpoint = ENV["SB_MQ"]
    host = endpoint
    # endpoint = endpoint.split(":")
  #   host = endpoint[0]
  #   port = endpoint[1]
 
    @connection = Bunny.new(:host => host)
    @connection.start
    @channel = @connection.create_channel
    @topic = @channel.topic(topic)  
    # ObjectSpace.define_finalizer( self, self.class.finalize(@connection) )
  end
  
  def send (message,key)
    @topic.publish(message,:routing_key => key)
    puts "Message #{message} sent to #{@topic} with #{key}"
  end
  
  def wait_to_receive(key,callback)
    @threads = []
    
    @threads << Thread.new {
      @queue = @channel.queue("",:exclusive => true)
      @queue.bind(@topic,:routing_key => key)
      puts "Waiting on #{@topic} with #{key}"
      begin
        @queue.subscribe(:block => true) do |delivery_info, properties, body|
          puts " [x] #{delivery_info.routing_key}:#{body}"
          callback.process(body)
        end
      rescue Interrupt => _
        @channel.close
        @connection.close
      end
    }
    @threads.each { |thr| thr.join }
  end
  
  # def self.finalize(connection)
 #    connection.close
 #  end
  
end