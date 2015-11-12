require 'sinatra'

# Dir["./analysers/*.rb"].each {|file| require file }

# require '../lib/datastore.rb'
require './docker_analyser.rb'

require 'json'

class DockerAnalyserService < Sinatra::Application

  def initialize
    super()
    #This is being set by a wiring which is not topic of this implementation
    @docker_analyser = DockerAnalyser.new()
  end
  
  
  get '/whoami' do 
    "Docker Analyser Service"
  end
  
  get '/analyse' do
    "To be implemented"
  end


end