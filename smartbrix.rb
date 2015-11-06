# This is used for evaluation purposes be sure all framework components are started first

require 'rubygems'
require 'bundler/setup'
require 'json'
require 'rest-client'
#Locals
# Dir["./analysers/*.rb"].each {|file| require file }
# Dir["./handlers/*.rb"].each {|file| require file }
# Dir["./managers/*.rb"].each {|file| require file }
# Dir["./lib/*.rb"].each {|file| require file}

#Loading the artifacts and storing them into the repositories. 

# files = Dir.glob("../madcatunits/examples/validation/**/*")
#
# tus=files.select{|file| file.split('.')[-2] == "tu"}
# dus=files.select{|file| file.split('.')[-2] == "du"}
# iss=files.select{|file| file.split('.')[-2] == "is"}
# dis=files.select{|file| file.split('.')[-2] == "di"}
#
# files.each do |path|
#
#   endpoint = path.split('.')[-2]
#   file = File.read(path)
#   data_hash = JSON.parse(file)
#   response = RestClient.post "http://localhost:9292/#{endpoint}", data_hash.to_json, :content_type => :json, :accept => :json
#   puts response.code
# end
#


#Simulate Transfer Requests

# http://localhost:8000/move?tu=CitizenInformationSystem&is=DedicatedServer


#Case 1 everything is here 
#I get a TU(name) and IS(name) check where it runs and transfer accordingly by selecting a DU / DI Instance










#Validate Transfer