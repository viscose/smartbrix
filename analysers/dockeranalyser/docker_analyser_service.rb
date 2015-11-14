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
    # name = nil;
    # command = nil;
    # if params.has_key?('name')
    #   params['name']
    # end
    #
    # if params.has_key?('command')
    #
    # end
    puts "Analyzing #{params["name"]} with #{params["command"]}"
    @docker_analyser.analyse(params["name"],params["command"])
  end


end