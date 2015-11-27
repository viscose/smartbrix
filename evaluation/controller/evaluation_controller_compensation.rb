require 'rest-client'
require 'bunny'
require 'csv'
require 'mongo'



#
@connection = Bunny.new(:host => "10.99.0.43")
@connection.start
@channel = @connection.create_channel

@queue = @channel.queue("compensation_queue", :durable => true)


client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'analytics')

perfomance_data = nil
csv_file = './normalised_results/vulnerabilities_500.csv'
csv_digest = './normalised_results/vulnerabilities_500_digest.csv'

analytics = client["vulnerabilities"].find
vulnerabilities = client["vulnerabilities"].find("vulnerabilities" => {"$exists" => true, "$gt" => {"$size" => 0}})

vulnerabilities.each do |document|
  
  msg = "#{document["pull_command"]},#{document["_id"]}"
  p msg
  @queue.publish(msg,:persistent=>true)
  
end

# Shuffle 
#
# commands = commands.shuffle
#
# commands.each do |msg|
#   @queue.publish(msg,:persistent => true)
# end



