

# Dir["./analysers/*.rb"].each {|file| require file }

# require '../lib/datastore.rb'

require 'rest-client'

class SmartbrixManager 
  
  
  def initialize(endpoint)
    @endpoint = endpoint
    # @dependency_manager = "http://localhost:7000"
    @connection = Bunny.new(:host => "192.168.99.100")
    @connection.start
    @channel = @connection.create_channel

    @queue = @channel.queue("task_queue", :durable => true)
    #
    # msg = "mikesplain/openvaspublic,docker pull mikesplain/openvas"
    #
    # @queue.publish(msg,:persistent => true)

    # @topic = @channel.topic("analysers")
    #
    # def send (message,key)
    #   @topic.publish(message,:routing_key => key)
    #   puts "Message #{message} sent to #{@topic} with #{key}"
    # end

    file = "./dockerurls.csv"
    puts file
    CSV.foreach(file) do |row|

      name = row[0].split(" ").first
      msg= "#{name},#{row[1]}"
      @queue.publish(msg,:persistent => true)

    end
  end
  
end