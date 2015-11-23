require 'csv'
require 'json'
require 'mongo'

require 'rest-client'


smartbrix_eval_1="128.130.172.190"
smartbrix_eval_2="128.130.172.196"

csv_file = "./performance_data/eval_run_500.csv"


client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'analytics')

file = File.read('./performance_data/eval_run_500.json')
# curl -G 'http://128.130.172.190:8086/db/cadvisor/series?u=root&p=root&pretty=true' --data-urlencode "q=select * from stats where container_name = 'reverent_dijkstra' and time > '2015-11-20 10:00:01.232'" | less 

performance_data_raw = JSON.parse(file)

puts performance_data_raw[0]["columns"]
puts performance_data_raw[0]["points"].count

CSV.open(csv_file,"wb") do |csv|
  csv << performance_data_raw[0]["columns"]
  # puts performance_data_raw["name"]
  performance_data_raw[0]["points"].each do |points|
    csv << points
  end
end

#
# analysed = client[:vulnerabilities].find()
# #{ vulnerabilities: {$exists: true, $gt: {$size: 0}} }
# vulnerable = client[:vulnerabilities].find({'vulnerabilities' => {"$exists" => true, "$gt" => {"$size" => 0}}})



# {
#     "name": "stats",
#     "columns": [
#         "time",
#         "sequence_number",
#         "cpu_cumulative_usage",
#         "tx_bytes",
#         "rx_errors",
#         "tx_errors",
#         "fs_usage",
#         "memory_working_set",
#         "fs_limit",
#         "machine",
#         "rx_bytes",
#         "container_name",
#         "fs_device",
#         "memory_usage"
#     ],
