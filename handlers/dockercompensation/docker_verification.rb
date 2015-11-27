gem 'docker-api'

require 'docker'
require './docker_model.rb'

require 'rest-client'


class DockerVerification
  
  #DOCKER_HOST="tcp://0.0.0.0:2376"  
  #Docker.url = DOCKER_HOST
  
  @docker_model = nil
  @vulnerabilities = {}
  @sharp_packagelist = {}
  @fuzzy_packagelist = {}
  @image_name = nil
  @image_history = nil
  @pull_command = nil
  @all_time_start = nil
  @all_time_end = nil
  @image_creation_date = nil
  @virtual_image_size = nil
  
  def initialize()
    @docker_model = DockerModel.new("base_image_ids.csv")
    @vulnerabilities = Hash.new
  end
  
  def analyse_image_id(test_id,flavour,image_name,object_id)
    
    
    @image_name = image_name
    starttime = Time.now
    
   
    if flavour 
      puts "Got flavour determining command"
      command = @docker_model.get_access_command(flavour)
      puts "got command:#{command}"
      packages = list_packages(test_id,flavour)
      
      # We need to remove the . from the keys otherwise we cant store them in mongodb.
      corrected_packages = Hash[packages.map { |k, v| [k.gsub(/\./,"_"), v] }]
      ##return analyse_sharp(packages) && analyse_fuzzy(packages)
      result = analyse_fuzzy(packages)
      
      
      
      puts "Finished analysis tyring to store them"
      endtime = Time.now
      if result != nil
        # Store them into the database
      
        database_URL = ENV["SB_DBURL"]

        begin
          elapsed_time = (endtime - starttime)*1000
          @all_time_end = Time.now
          response = RestClient.post "http://admin:admin@#{database_URL}/analytics/verified_compensations",{ 'image_name' => @image_name,'image_id' => test_id,'flavour' => flavour, 'runtime' => elapsed_time, 'original_id' => object_id, 'timestamp' => "#{DateTime.now.to_s}", 'packages' => packages.flatten.to_s, 'packages_hash' => corrected_packages,'vulnerabilities' => @vulnerabilities }.to_json, :content_type => :json, :accept => :json
        #RestClient.post "http://admin:admin@192.168.99.100:8080/analytics/vulnerabilities",{ 'image_id' => 1}.to_json, :content_type => :json, :accept => :json
          puts response
          
          return true  
        rescue => e
          puts "Couldnt store data due to #{e.inspect}"
          return false
        end
      end
      
      
      
      # found = analyse_sharp(packages)
#
#       if found == false
#
#         return analyse_fuzzy(packages)
#       else
#         return found
#       end
      
    else
      puts "Could not determine packages analytics failed for:#{test_id}"
      return false
      
    end

    
  end
  
  
  private 
  
  def analyse_sharp(packages)
    @sharp_packagelist = packages
    analyse_packages(packages)
    
  end
  
  #TODO Adapt to analytics !!!!
  #docker inspect -f '{{.Created}}' f348
  def analyse_fuzzy(packages)
    
    combined_packages = packages.group_by{|x| x[0].split("-").first}.select { |k,v| v.length > 1 }.inject({}) { |i, k| i[k[0]] = k[1][0][1];  i } 
    packages = combined_packages.merge(packages)
  
    # packages = packages.group_by{|x| x[0].split("-").first}.select { |k,v| v.length > 1 }
    @fuzzy_packagelist = packages
    analyse_packages(packages)
    
  end
  
  def analyse_packages(packages)
    found = false
    
    packages.each do |name,version|
      
      cveurl = ENV["SB_CVEHUB"]
      # response = RestClient.get 'http://0.0.0.0:8000/cves', {:params => {'name' => name}}#, 'version' => version}}
      
      #(\d+\.)?(\d+\.)?(\*|\d+)
      puts "Analysing package list"
      version = version.match(/(?:[^:]+:)?([\d\w]+(?:\.[\d\w]+)*)(?:-.+)?/)[1]
      puts "Trying to query cves from #{cveurl}"
      
      response = RestClient.get "http://#{cveurl}/cves", {:params => {'name' => name, 'version' => version}}
      
      
      if response != "[]"
        # puts response
        if name != nil
          puts "Trying to insert: #{name}"
          @vulnerabilities["#{name}"] = response
        end
        found = true
      else
        puts "#{name} without vulnerability"
      end
      
    end
    
    puts "Finished analytics"
    
    return found
  end
  
  
  def list_packages(image_id, flavour)
    
    command = @docker_model.get_access_command(flavour) 
    puts "Trying to run"
    shellcommand = "docker run -e \"COLUMNS=300\" --entrypoint=\/bin\/sh -it --rm #{image_id} -c \'#{command}\'"
    puts shellcommand
    result = `#{shellcommand}`
    puts "Run finished"
    puts result
    
    
    case flavour
    when "ubuntu","debian"
      return parse_dpkg_response(result)
    when "fedora","centos"
      return parse_yum_response(result)
    when "alpine"
      return parse_apk_response(result)
      
    end
    
    
  end
  
  
  def filter_package_name(name)
    
    subs  = name.gsub!(/\:.*/,'')
    
    if subs != nil
      return subs
    else
      return name
    end
  end


  
  def parse_dpkg_response(result)
    
    packages = {}
    
    result_linewise = result.split("\n").reject{|item| !item.start_with?("ii")}.map{|item| item.gsub!(/\s+/, ',')}
  
    result_linewise.each do |package|
      
      package_elements = package.split(",")
      packages[filter_package_name(package_elements[1])]=package_elements[2]
      
    end
    
    return packages
    
  end
  
  
  def parse_yum_response(result)

    packages = {}
    
    result_linewise = result.split("\n")
    
    
    match = result_linewise.find {|element| element.start_with?("Installed")}
    match_index = result_linewise.index(match)
    
    result_linewise.shift(match_index+1)
    
    result_linewise = result_linewise.map{|item| item.gsub!(/\s+/, ',')}
    
    result_linewise.each do |package|
      
      package_elements = package.split(",")
      packages[filter_package_name(package_elements[0])]=package_elements[1]
      
    end 
      
    return packages
  end
  
  def parse_apk_response(result)
    
    packages = {}
    
    result_linewise = result.split("\n").reject{|item| item.start_with?("WARNING")}
    
    result_linewise.each do |package|
      
      matches = package.match /^(?<package>(?:[^\d][^-]*)(?:-[^\d][^-]*)*)-(?<version>\d+(?:\.[^-]+)*)(?:-(?<patch>.*))?$/
      
      if matches
          packages[filter_package_name(matches[:package])]=matches[:version] # TODO Should include patch as well
      end
          
    end 
    
    
    return packages
  end
  
end