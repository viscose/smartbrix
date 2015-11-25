require 'csv'
require 'json'
require 'mongo'
require 'gnuplot'
require 'rest-client'

client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'analytics')

perfomance_data = nil
csv_file = './normalised_results/vulnerabilities_500.csv'
csv_digest = './normalised_results/vulnerabilities_500_digest.csv'

analytics = client["vulnerabilities"].find
vulnerabilities = analytics.find("vulnerabilities" => {"$exists" => true, "$gt" => {"$size" => 0}})

start_time = client["vulnerabilities"].find.sort(:timestamp => -1).limit(1).first["timestamp"]
end_time = client["vulnerabilities"].find.sort(:timestamp => 1).limit(1).first["timestamp"]
puts start_time
puts end_time


official = []
inofficial = []

official_vulnerable = []
inofficial_vulnerable = []


#Normalising file
CSV.open(csv_file,"wb") do |csv|
  csv << ["image_name","image_id","flavour","runtime","complete_runtime","size","vulnerabilities_count","timestamp"]
  analytics.each do |document|
    # puts document
    
    if document["image_name"]=~ /^[^\/]*$/ 
      official << document
      if document["vulnerabilities"].keys.count > 0
        official_vulnerable << document
      end
    else
      inofficial << document
      if document["vulnerabilities"].keys.count > 0
        inofficial_vulnerable << document
      end
    end
    
    csv << [document["image_name"],document["image_id"],document["flavour"],document["runtime"],document["complete_runtime"],document["virtual_image_size"],document["vulnerabilities"].keys.count,document["timestamp"]]
  end
end


#Average runtime / Overall runtime


CSV.open(csv_digest,"wb") do |csv|
  csv << ["total","analysed","vulnerabilities","official","inofficial","official_vulnerable","inofficial_vulnerable"]
  csv << [500,analytics.count,official_vulnerable.count + inofficial_vulnerable.count,official.count,inofficial.count,official_vulnerable.count,inofficial_vulnerable.count]
  
end



# puts analytics.count
# p vulnerabilities.count

### QUERIES
#
# { vulnerabilities: {$exists: true, $gt: {$size: 0}} }
#
# # Official
# { image_name: {$regex: '^[^/]*$'} }
#
# # Not official
# { image_name: {$regex: '.+/.+'} }