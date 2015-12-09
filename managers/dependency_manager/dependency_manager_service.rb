require 'sinatra'

# Dir["./analysers/*.rb"].each {|file| require file }

# require '../lib/datastore.rb'
require './dependency_manager.rb'

require 'json'

class DependencyManagerService < Sinatra::Application

  def initialize
    super()
    #This is being set by a wiring which is not topic of this implementation
    # @smartbrixmanager = SmartbrixManager.new("http://localhost:9292")
  end
  
  
  get '/whoami' do 
    "Dependency Manager and Request Handler"
  end
  
  get '/credentials' do
    "To be implemented"
  end
  
  get '/credentials' do
    "To be implemented"
  end
  
  get '/artifacts' do
    "To be implemented"
  end
  


end