require 'rest-client'
require 'bunny'
require 'csv'



#
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

#file = "./dockerurls.csv"
file = "./dockerurls_set3.csv"
puts file
i = 0
start_at=0

commands = []

CSV.foreach(file) do |row|
  if i == 2001
   break
  end
  if i > start_at
    name = row[0].split(" ").first
    msg= "#{name},#{row[1]}" 
    puts msg
    commands << msg 
    # @queue.publish(msg,:persistent => true)
  end 
  i=i+1
end

# Shuffle 

commands = commands.shuffle

commands.each do |msg|
  @queue.publish(msg,:persistent => true)
end



