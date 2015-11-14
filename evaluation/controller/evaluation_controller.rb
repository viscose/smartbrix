require 'rest-client'
require 'bunny'
require 'csv'




@connection = Bunny.new(:host => "192.168.99.100")
@connection.start
@channel = @connection.create_channel
@topic = @channel.topic("analysers")  

def send (message,key)
  @topic.publish(message,:routing_key => key)
  puts "Message #{message} sent to #{@topic} with #{key}"
end

file = "./dockerurls.csv"
puts file
CSV.foreach(file) do |row|
  puts row
  
end