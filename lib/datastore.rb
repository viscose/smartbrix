require 'redis'
require 'json'

class Datastore

  @@isolationCounter=1
  @redis = nil

  def initialize(name,host="localhost")
    # Ensure it is a new database each time this happens
    @redis = Redis.new(:db => @@isolationCounter)
    @@isolationCounter+=1
    @name = name
    puts "Initialised new store for #{name} internally represented by #{@@isolationCounter-1}"
  end
  
  def retrieve (name)
    retrieved = @redis.get(name)
    if retrieved != nil
      return JSON.parse(@redis.get(name))
    else
      return {}
    end
  end

  def store (name,object)
    @redis.set name,object.to_json
  end
  
  def search (query)
    @redis.keys(query)
  end
  
  def get_all_keys ()
    @redis.keys('*')
  end
    
end




