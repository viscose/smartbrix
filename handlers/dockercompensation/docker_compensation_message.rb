require './lib/data_exchange.rb'
require './docker_compensation.rb'

class DockerCompensationMessage
  
    
  def start
    # Set the topic that u want to listen to
    dataexchange = DataExchange.new('compensation')
    dataexchange.wait_to_receive("artifact.uri",self)
  
  end

  def process(message)
    compensation = DockerCompensation.new
    message = message.split(",")
    compensation.compensate(message[0],message[1])
  end
  
end  

DockerCompensationMessage.new.start
