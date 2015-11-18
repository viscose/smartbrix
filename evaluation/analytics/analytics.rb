require 'csv'
require 'json'
require 'mongo'
require 'gnuplot'


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

verified_vulnerabilities = []

vulnerable.each do |document|
  vulnerabilities = verify_vulnerability(document[:packages_hash],document[:vulnerabilities])
  if !vulnerabilities.empty?
    puts "#{document[:image_name]} from basetype #{document[:flavour]} vulnerable #{vulnerabilities}"
    verified_vulnerabilities << document
  else
    puts "#{document[:image_name]} from basetype #{document[:flavour]} not vulnerable"
  end
  
end

puts verified_vulnerabilities.count

grouped_by_flavour = verified_vulnerabilities.group_by{|x| x[:flavour]}

grouped_by_flavour.each do |flavour,elements|
  puts flavour
  puts elements.count
end

grouped_by_vulnerable_packages = verified_vulnerabilities.group_by{|x| x[:vulnerabilities]}

grouped_by_vulnerable_packages.each do |package,cves|
  puts package.keys.first
  # puts packagename
  puts cves.count
end
# puts grouped_by_flavour

# packages = packages.group_by{|x| x[0].split("-").first}.select { |k,v| v.length > 1 }



#
# processing_time = 0
# analysed.each do |document|
#   processing_time += document[:runtime]/1000
#
# end
# puts processing_time/analysed.count


# Gnuplot.open do |gp|
#   Gnuplot::Plot.new(gp) do |plot|
#
#     plot.terminal "gif"
#     plot.output ("./sin_wave.gif")
#     plot.title  "Histogram example"
#     plot.style  "data histograms"
#     plot.xtics  "nomirror rotate by -45"
#
#
#     titles = %w{decade Austria Hungary  Belgium}
#     data = [
#       ["1891-1900",  234081,  181288,  18167],
#       ["1901-1910",  668209,  808511,  41635],
#       ["1911-1920",  453649,  442693,  33746],
#       ["1921-1930",  32868,   30680,   15846],
#       ["1931-1940",  3563,    7861,    4817],
#       ["1941-1950",  24860,   3469,    12189],
#       ["1951-1960",  67106,   36637,   18575],
#       ["1961-1970",  20621,   5401,    9192],
#     ]
#
#     x = data.collect{|arr| arr.first}
#     (1..3).each do |col|
#       y = data.collect{|arr| arr[col]}
#       plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds|
#         ds.using = "2:xtic(1)"
#         ds.title = titles[col]
#       end
#     end
#
#   end
# end

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