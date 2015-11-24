require 'csv'
require 'json'
require 'mongo'
require 'gnuplot'
require 'rest-client'

client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'analytics')


### QUERIES
#
# { vulnerabilities: {$exists: true, $gt: {$size: 0}} }
#
# # Official
# { image_name: {$regex: '^[^/]*$'} }
#
# # Not official
# { image_name: {$regex: '.+/.+'} }