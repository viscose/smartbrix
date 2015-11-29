require 'csv'
require 'json'
require 'mongo'
require 'gnuplot'
require 'rest-client'


def mean(array)
	 array.inject(array.inject(0) { |sum, x| sum += x } / array.size.to_f)
end

client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'analytics')

perfomance_data = nil


verified_compensations = client["verified_compensations"].find

success = []
unsuccessful = []

verified_compensations.each do |document|
  # puts document
  vulnerable_image = client["vulnerabilities"].find("image_name" => "#{document["image_name"]}").first
  
  if vulnerable_image["vulnerabilities"].keys.count > document["vulnerabilities"].count
    success << document
    puts "For #{document["image_name"]} we compensated to #{document["vulnerabilities"].keys.count} from #{vulnerable_image["vulnerabilities"].keys.count}"
  else
    puts "Could not improve for #{document["image_name"]}"
    unsuccessful << document
  end
end

puts "Sucessful for #{success.count} from #{verified_compensations.count}"
