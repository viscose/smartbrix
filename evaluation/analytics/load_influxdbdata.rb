require 'csv'
require 'json'
require 'mongo'

require 'rest-client'


smartbrix_eval_1="128.130.172.190"
smartbrix_eval_2="128.130.172.196"


client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'analytics')

file = File.read('./performance_data/smartbrix-eval-1.json')
# curl -G 'http://128.130.172.190:8086/db/cadvisor/series?u=root&p=root&pretty=true' --data-urlencode "q=select * from stats where container_name = 'reverent_dijkstra' and time > '2015-11-20 10:00:01.232'" | less 


#
# analysed = client[:vulnerabilities].find()
# #{ vulnerabilities: {$exists: true, $gt: {$size: 0}} }
# vulnerable = client[:vulnerabilities].find({'vulnerabilities' => {"$exists" => true, "$gt" => {"$size" => 0}}})
