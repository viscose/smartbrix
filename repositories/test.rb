require 'rubygems'
require 'bundler/setup'

require 'json'
require 'rest-client'

# Dir["../../../lib/*.rb"].each {|file| require file }
require '../lib/datastore.rb'
datastore_tu = Datastore.new('technicalunits')
datastore_du = Datastore.new('deploymentunits')

file = File.read("../../madcatunits/examples/citizeninformationsystem.tu.json")

data_hash = JSON.parse(file)
# puts data_hash
# datastore_tu.store(data_hash["name"],data_hash)
# puts "Stored"
# puts datastore_tu.retrieve(data_hash["name"])
# puts data_hash["name"]


response = RestClient.post "http://localhost:9292/is", data_hash.to_json, :content_type => :json, :accept => :json
puts response.code