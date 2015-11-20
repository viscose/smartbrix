require 'sinatra'

# Dir["./analysers/*.rb"].each {|file| require file }

# require '../lib/datastore.rb'
require './smartbrix_manager.rb'

require 'json'

class SmartbrixManagerService < Sinatra::Application

  def initialize
    super()
    #This is being set by a wiring which is not topic of this implementation
    @smartbrixmanager = SmartbrixManager.new("http://localhost:9292")
  end
  
  
  get '/whoami' do 
    "Smart Brix Manager and Request Handler"
  end
  
  get '/analyse' do
    "To be implemented"
  end
  
  get '/inspection' do
    
    
  end
  
  get '/introspection' do
    
  end
  
  
  get '/' do
    "Hello yo"
    erb :'/home'
    
  end


end