require 'csv'
require 'json'
require 'mongo'
require 'gnuplot'
require 'rest-client'


# Helpers
def mean(array)
	 array.inject(array.inject(0) { |sum, x| sum += x } / array.size.to_f)
end

def generate_csv_files(set_size,csv_file_name,csv_digest_name,csv_condensed_name,database_name)

  client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'analytics')
  
  perfomance_data = nil
  csv_file = csv_file_name#'./consolidated/vulnerabilities.csv'
  csv_digest = csv_digest_name#'./consolidated/vulnerabilities_digest.csv'
  csv_condensed = csv_condensed_name#'./consolidated/vulnerabilities_condensed.csv'

  analytics = client["#{database_name}"].find
  vulnerabilities = client["#{database_name}"].find("vulnerabilities" => {"$exists" => true, "$gt" => {"$size" => 0}})

  start_time = client["#{database_name}"].find.sort(:timestamp => -1).limit(1).first["timestamp"]
  end_time = client["#{database_name}"].find.sort(:timestamp => 1).limit(1).first["timestamp"]
  puts start_time
  puts end_time


  official = []
  inofficial = []

  official_vulnerable = []
  inofficial_vulnerable = []

  processing_runtime = []
  complete_runtime = []
  total_image_size = []




  # a = a.sort{|a,b| a['age'] <=> b['age']}


  # Data cleaning removing infinities


  cleaned_analytics = analytics.reject{|item| item["complete_runtime"].infinite? || item["runtime"].infinite?}
  cleaned_analytics = cleaned_analytics.reject{|item| item["runtime"].infinite?}

  sorted_by_complete_run_time = cleaned_analytics.sort{|a,b| a["complete_runtime"] <=> b["complete_runtime"]}


  puts "Analytics was #{analytics.count} now is #{cleaned_analytics.count}"

  # sorted_by_runtime =


  # Normalising file
  CSV.open(csv_file,"wb") do |csv|
    csv << ["image_name","image_id","flavour","runtime","complete_runtime","size","vulnerabilities_count","timestamp","packages_count"]
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

      processing_runtime << document["runtime"]/1000 unless document["runtime"].infinite?
      complete_runtime << document["complete_runtime"] unless document["complete_runtime"].infinite?
      total_image_size << document["virtual_image_size"].to_f
    
    
      timestamp = Time.parse(document["timestamp"])
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
      csv << [document["image_name"],document["image_id"],document["flavour"],document["runtime"]/1000,document["complete_runtime"],document["virtual_image_size"],document["vulnerabilities"].keys.count,timestamp,document["packages_hash"].keys.count]
      # csv << [document["runtime"]/1000,document["complete_runtime"],document["virtual_image_size"],document["vulnerabilities"].keys.count,document["timestamp"]]
    end
  end

  #
  # #Average runtime / Overall runtime Digests
  #

  CSV.open(csv_digest,"wb") do |csv|
    csv << ["total","analysed","vulnerabilities","official","inofficial","official_vulnerable","inofficial_vulnerable"]
    csv << [set_size,analytics.count,official_vulnerable.count + inofficial_vulnerable.count,official.count,inofficial.count,official_vulnerable.count,inofficial_vulnerable.count]

  end


  # lowest = arr.min
  # highest = arr.max
  # total = arr.inject(:+)
  # len = arr.length
  # average = total.to_f / len # to_f so we don't get an integer result
  # sorted = arr.sort
  # median = len % 2 == 1 ? sorted[len/2] : (sorted[len/2 - 1] + sorted[len/2]).to_f / 2


 
  #
  CSV.open(csv_condensed,"wb") do |csv|
    csv << ["set","complete_runtime_total","complete_runtime_max","complete_runtime_min","complete_runtime_avg","processing_time_total","processing_time_min","processing_time_max","processing_time_avg","total_image_size","image_size_min","image_size_max","image_size_avg"]
  
    processing_runtime_total = processing_runtime.inject(:+)
    processing_runtime_min = processing_runtime.min
    processing_runtime_max = processing_runtime.max
    processing_runtime_avg = processing_runtime_total.to_f / processing_runtime.length
  
    complete_runtime_total = complete_runtime.inject(:+)
    complete_runtime_min = complete_runtime.min
    complete_runtime_max = complete_runtime.max
    complete_runtime_avg = complete_runtime_total.to_f / complete_runtime.length
  
    total_image_size_total = total_image_size.inject(:+)
    total_image_size_min = total_image_size.min
    total_image_size_max = total_image_size.max
    total_image_size_avg = total_image_size_total.to_f / total_image_size.length
  
    csv << [set_size,complete_runtime_total,complete_runtime_max,complete_runtime_min,processing_runtime_total,processing_runtime_min,processing_runtime_max,processing_runtime_avg,total_image_size_total,total_image_size_min,total_image_size_max,total_image_size_avg]
    # csv << [set_size,complete_runtime.reduce(0){|sum,a| sum+a},complete_runtime.max,complete_runtime.min,runtime.reduce(0){|sum,a|sum+a},runtime.min,runtime.max]

  end
  #

  p "Finished #{analytics.count} with #{processing_runtime.count} and #{complete_runtime.count} "
  duration = Time.parse(start_time)-Time.parse(end_time)
  p "Should be #{end_time} and #{start_time} with complete runtime #{duration}"

  # p "Runtime min:#{runtime.min} Runtime max:#{runtime.max} Average runtime: #{runtime.reduce(0){|sum, a| sum + a}}Complete Runtime min:#{complete_runtime.min} Complete Runtime max:#{complete_runtime.max}"
  #
  #

end

target_folder = './consolidated/'


set_size = 250
oneinstance=["oneinstance_250_1","oneinstance_250_2","oneinstance_500_1","oneinstance_1000_1"]
twoinstances=["twoinstances_250_1","twoinstances_250_2","twoinstances_250_3","twoinstances_500_1","twoinstances_500_2","twoinstances_500_3","twoinstances_1000_1","twoinstances_1000_2","twoinstances_1000_3"]


twoinstances.each do |instance|
  set_size = instance.split("_")[1]
  csv_file_name = target_folder+"twoinstances/"+instance+".csv"
  csv_digest_name = target_folder+"twoinstances/"+instance+"_digest.csv"
  csv_condensed_name = target_folder+"twoinstances/"+instance+"_condensed.csv"
  
  puts "Outputting #{instance} with #{csv_file_name} and #{csv_digest_name} and #{csv_condensed_name} and set: #{set_size}"
  generate_csv_files(set_size,csv_file_name,csv_digest_name,csv_condensed_name,instance)
  
end

