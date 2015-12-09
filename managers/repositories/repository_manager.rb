require 'sinatra'

# Dir["./analysers/*.rb"].each {|file| require file }

require '../lib/datastore.rb'

require 'json'

class RepositoryManager < Sinatra::Application
  
  def initialize 
    super()
    puts "Initializing stores"
    # @technical_unit_store = Datastore.new("tu")
   #  @deployment_unit_store = Datastore.new("du")
   #  @infrastructure_specification_store = Datastore.new("is")
   #  @deployment_instance_store = Datastore.new("di")
  end

  get '/whoami' do
    "Repository Manager"
  end
  
end