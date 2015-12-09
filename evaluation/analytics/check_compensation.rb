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

csv_file = "./consolidated/compensations/compensation_results_50_2.csv"

compensations = client["compensations"].find


CSV.open(csv_file,"wb") do |csv|
  csv << ["image_name","image_id","runtime","pull_time","vulnerabilities_count_before","vulnerabilities_count_after","improvement","timestamp"]
  compensations.each do |document|
    puts document

    # processing_runtime << document["runtime_total"]/1000 unless document["runtimte_total"].infinite?
  #   pull_time << document["pull_time"] unless document["pull_time"].infinite?
  #   total_image_size << document["virtual_image_size"].to_f
  #
  
    timestamp = Time.parse(document["timestamp"])
    
    verified_compensation = client["verified_compensations"].find(:image_id => "#{document["compensated_image_id"]}").first
    
    # TODO Thinks
    vulnerable_image = client["vulnerabilities"].find("image_name" => "#{document["image_name"]}").first
  
    vulnerabilities_before = vulnerable_image["vulnerabilities"].keys.count
    vulnerabilities_after = verified_compensation["vulnerabilities"].count
    improvement = 0
  
    if vulnerabilities_before > vulnerabilities_after
      improvement = 1
  
    else
      improvement = 0
    end
    
    # if !document["complete_runtime"].infinite?
 #      starttime_stamp = timestamp - document["complete_runtime"]
 #    else
 #
 #    end
 #    starttime_stamp = timestamp - document["complete_runtime"]
 #    if !document["runtime"].infinite?
 #      processingtime_stamp = starttime_stamp + document["runtime"]/1000
 #    else
 #      processingtime_stamp = "NA"
 #    end
  
  
    # complete_runtime << document["complete_runtime"] unless document["complete_runtime"].infinite?
    csv << [document["image_name"],document["image_id"],document["runtime_total"]/1000,document["pull_time"],vulnerabilities_before,vulnerabilities_after,timestamp]
    # csv << [document["runtime"]/1000,document["complete_runtime"],document["virtual_image_size"],document["vulnerabilities"].keys.count,document["timestamp"]]
  end
end

puts "Sucessful for #{success.count} from #{verified_compensations.count}"
