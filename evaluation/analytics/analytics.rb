require 'csv'
require 'json'
require 'mongo'
require 'gnuplot'


# file = File.read('./datasets/vulnerabilities.json')
# data_hash = JSON.parse(file)
#
# puts "done"

def verify_vulnerability(packages,vulnerabilities)
  package, cpe = vulnerabilities.first
  cpe = JSON.parse(cpe)
  checklist = []
  verified_vulnerabilities = []
  packages.each do |name,versions|
    if name =~/^#{package}/    
      checklist << versions[/^\d*.\d*\.\d*/]
    end
  end
  
  if !checklist.empty?
    checklist.each do |version|
      # p ary.find { |h| h['product'] == 'bcx' }['href']
      cpe.each do |vulnerability|
        # puts vulnerability
        if vulnerability["vulnerable_configurations"][/#{version}/] == version || vulnerability["vulnerable_configurations"][/#{version}/] == version
          # puts "Valid vulnerable configuration"
          verified_vulnerabilities << vulnerability
        end
      end
      
    end
  end
  
  return verified_vulnerabilities
end



client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'analytics')

analysed = client[:vulnerabilities].find()
#{ vulnerabilities: {$exists: true, $gt: {$size: 0}} }
vulnerable = client[:vulnerabilities].find({'vulnerabilities' => {"$exists" => true, "$gt" => {"$size" => 0}}})

# client[:vulnerabilities].find({'flavour' => "ubuntu" }).each do |document|
#   #=> Yields a BSON::Document.
#   puts document[:image_name]
# end

puts "From #{analysed.count} images we found #{vulnerable.count} with potential vulnerabilities "
percentage_of_vulnerable = 100/analysed.count.to_f * vulnerable.count.to_f
puts percentage_of_vulnerable

vulnerable.each do |document|
  vulnerabilities = verify_vulnerability(document[:packages_hash],document[:vulnerabilities])
  if !vulnerabilities.empty?
    puts "#{document[:image_name]} from basetype #{document[:flavour]} vulnerable"
  else
    puts "#{document[:image_name]} from basetype #{document[:flavour]} not vulnerable"
  end
  
end



#
# processing_time = 0
# analysed.each do |document|
#   processing_time += document[:runtime]/1000
#
# end
# puts processing_time/analysed.count




#
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