require './lib/data_exchange.rb'
require './docker_analyser.rb'

class DockerAnalyserMessage
  
    
  def start
    # Set the topic that u want to listen to
    dataexchange = DataExchange.new('analysers')
    dataexchange.wait_to_receive("artifact.uri",self)
  
  end

  def process(message)
    analyser = DockerAnalyser.new
    message = message.split(",")
    analyser.analyse(message[0],message[1])
  end
  
end  

DockerAnalyserMessage.new.start
