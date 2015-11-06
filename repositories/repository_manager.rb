require 'sinatra'

# Dir["./analysers/*.rb"].each {|file| require file }

require '../lib/datastore.rb'

require 'json'

class RepositoryManager < Sinatra::Application
  
  def initialize 
    super()
    puts "Initializing stores"
    @technical_unit_store = Datastore.new("tu")
    @deployment_unit_store = Datastore.new("du")
    @infrastructure_specification_store = Datastore.new("is")
    @deployment_instance_store = Datastore.new("di")
  end

  get '/whoami' do
    "TU,DU,IS Repository Manager"
  end
  
  post '/tu' do
      data = JSON.parse request.body.read
      puts "Received #{data}"
      @technical_unit_store.store(data['name'],data)
  end
  
  get '/tu' do 
    return_message = {}
    if params.has_key?('name')
      return_message=@technical_unit_store.retrieve(params['name'])
    end
    
    if params.has_key?('search')
      return_message=@technical_unit_store.search(params['search'])
    end
    
    if params.empty?
      return_message=@technical_unit_store.get_all_keys()
    end
    return_message.to_json
  end
  
  post '/is' do
      data = JSON.parse request.body.read
      puts "Received #{data}"
      @infrastructure_specification_store.store(data['name'],data)
  end
  
  
  get '/is' do
    return_message = {}
    if params.has_key?('name')
      
      puts "Retrieving #{params['name']}"
      found = @infrastructure_specification_store.retrieve(params['name'])
      puts "Found #{found}"
      return_message = found
    end
    
    if params.has_key?('search')
      return_message = @infrastructure_specification_store.search(params['search'])
    end
    
    if params.empty?
      return_message=@infrastructure_specification_store.get_all_keys()
    end
    
    return_message.to_json
    
  end
  
  post '/du' do
      data = JSON.parse request.body.read
      puts "Received #{data}"
      @deployment_unit_store.store(data['name'],data)
  end
  
  
  
  get '/du' do 
    return_message = {}
    if params.has_key?('name')
      return_message=@deployment_unit_store.retrieve(params['name'])
    end
    
    if params.has_key?('search')
      return_message=@deployment_unit_store.search(params['search'])
    end
    
    if params.empty?
      return_message=@deployment_unit_store.get_all_keys()
    end
    return_message.to_json
  end
  
  post '/di' do
      data = JSON.parse request.body.read
      puts "Received #{data}"
      @deployment_instance_store.store(data['name'],data)
  end
  
  
  
  get '/di' do 
    return_message = {}
    if params.has_key?('name')
      return_message=@deployment_instance_store.retrieve(params['name'])
    end
    
    if params.has_key?('search')
      return_message=@deployment_instance_store.search(params['search'])
    end
    
    if params.empty?
      return_message=@deployment_instance_store.get_all_keys()
    end
    return_message.to_json
    
  end
  
  

end