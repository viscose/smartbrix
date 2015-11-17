require 'csv'
require 'json'
require 'mongo'
require 'gnuplot'
require 'influxdb'


# file = File.read('./datasets/vulnerabilities.json')
# data_hash = JSON.parse(file)
#
# puts "done"

# client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'analytics')
#
# analysed = client[:vulnerabilities].find()
#
#
# client[:vulnerabilities].find().each do |document|
#   #=> Yields a BSON::Document.
#   puts document[:image_name]
# end

# Influx 
#
smartbrix_eval_1_influx = "128.130.172.190"
influxdb = InfluxDB::Client.new(host: smartbrix_eval_1_influx, port: "8086", user:"root", password:"root")

influxdb.list_databases

# Gnuplot.open do |gp|
#   Gnuplot::Plot.new( gp ) do |plot|
#
#     plot.terminal "gif"
#     plot.output ("./sin_wave.gif")
#
#
#     plot.xrange "[-10:10]"
#     plot.title  "Sin Wave Example"
#     plot.ylabel "x"
#     plot.xlabel "sin(x)"
#     plot.style "line 1 lc rgb '#8b1a0e' pt 1 ps 1 lt 1 lw 2"
#
#     plot.data << Gnuplot::DataSet.new( "sin(x)" ) do |ds|
#       ds.with = "lines"
#       ds.linewidth = 4
#     end
#
#   end
#
# end


# file = "./dockerurls.csv"
# puts file
# CSV.foreach(file) do |row|
#
#   name = row[0].split(" ").first
#   msg= "#{name},#{row[1]}"
#   @queue.publish(msg,:persistent => true)
#
# end