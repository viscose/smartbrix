require 'sinatra'

# Dir["./analysers/*.rb"].each {|file| require file }

# require '../lib/datastore.rb'
require './smartfabric_manager.rb'

require 'json'

class SmartfabricManagerService < Sinatra::Application

  def initialize
    super()
    #This is being set by a wiring which is not topic of this implementation
    @smartfabricmanager = SmartfabricManager.new("http://localhost:9292")
  end
  
  
  get '/whoami' do 
    "Smart Fabric Manager and Request Handler"
  end

  get '/move' do
    response = {}
    # We want to move a 
    tuname = params["tu"]
    # To a new 
    isname = params["is"]
    puts "Request to move #{tuname} to #{isname}"
    @smartfabricmanager.move(tuname,isname)
    response.to_json
    
  end
  
  get '/analyse' do
    "To be implemented"
  end


end