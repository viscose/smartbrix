gem 'docker-api'

require 'docker'
require './docker_model.rb'

require 'rest-client'


class DockerAnalyser
  
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
  
  def analyse(package_name,pull_command)
    @all_time_start = Time.now
    begin
      puts "Trying to pull #{package_name} with #{pull_command}"
      # result = `#{pull_command}`
      @pull_command = pull_command
      @image_name = pull_command.split(" ").last
      
    
      puts @image_name
    
      #result = Docker::Image.create('fromImage' => "#{@image_name}:latest")
      result = system("#{pull_command}:latest")

      image = nil 
      if result 
      
        puts result

        image = Docker::Image.get(@image_name)
        @image_history = image.history
        @image_creation_date= `docker inspect -f '{{.Created}}' #{image.id}`
        @virtual_image_size= `docker inspect -f '{{.VirtualSize}}' #{image.id}`
        #docker inspect -f '{{.Created}}' d08adb7aae54
        puts "Analysing image with: #{image}"
        analyse_image_id(image.id)
      
      else
        puts "Could not pull image #{@image_name}:latest"
      end
    
    
      
      # should clean up as well
      #image.remove(:force => true)
      if system("docker rmi #{@image_name}:latest")
        puts "Cleaned up"
      end
      # if system("docker rmi $(docker images -q)")
 #        puts "Cleaned up dangling"
 #      end
      if system("docker rm -v $(docker ps -a -q -f status=dead)")
        puts "Cleaned up dead containers"
      end
      if system("docker rm -v $(docker ps -a -q -f status=exited)")
        puts "Cleaned up dead containers"
      end
      
      puts "Finished"
      return true 
    rescue => e
      puts "Exception while trying to pull the image #{e.inspect}"
      puts "Trying to cleanup anyway"
      if system("docker rmi #{@image_name}:latest")
        puts "Cleaned up"
      end
      # #TODO REMOVE
#       if system("docker rmi $(docker images -q)")
#         puts "Cleaned up dangling"
#       end
#       if system("docker rm -v $(docker ps -a -q -f status=dead)")
#         puts "Cleaned up dead containers"
#       end
      
      
      return false
    end
  
    
  end
  
  def analyse_image_id(test_id)
    
    starttime = Time.now
    
    flavour = determine_baseimage_flavour(test_id)
    puts flavour
    
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
        url = "http://admin:admin@#{database_URL}/analytics/vulnerabilities"
        puts url
        
        begin
          elapsed_time = (endtime - starttime)*1000
          @all_time_end = Time.now
          response = RestClient.post "http://admin:admin@#{database_URL}/analytics/vulnerabilities",{ 'image_name' => @image_name,'image_id' => test_id, 'pull_command' => @pull_command,'flavour' => flavour, 'runtime' => elapsed_time,'image_creation_date' => @image_creation_date,'virtual_image_size' => @virtual_image_size,'complete_runtime' => (@all_time_end-@all_time_start),'history' => @image_history,'timestamp' => "#{DateTime.now.to_s}", 'packages' => packages.flatten.to_s, 'packages_hash' => corrected_packages,'vulnerabilities' => @vulnerabilities }.to_json, :content_type => :json, :accept => :json
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
   
  ## Currently only a test method. 
  def test()
  
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
      # Parse version
      # First we check wheter it is an aggregated package or not then we apply some basic regex
      # Retired
      # if version.is_a?(Array)
 #        # We just take the first version we find
 #        checking = version.flatten
 #        checking.each do |candidate|
 #          version = candidate.match(/(\d+\.)?(\d+\.)?(\*|\d+)/)
 #          if version != nil
 #            version = version.to_s
 #            break
 #          end
 #
 #
 #        end
 #
 #      else
 #        version = version.match(/(\d+\.)?(\d+\.)?(\*|\d+)/).to_s
 #      end
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
  
  
  def determine_baseimage_flavour(image_id)
    image = Docker::Image.get(image_id)
    history = image.history.reverse
  
    flavour = nil

    # First we look if we know the base image
    history.each do |entry|
      puts entry["Id"]

      flavour = @docker_model.determine_flavour("#{entry["Id"]}")
      if flavour != nil
        break;
      end

    end

    # If we couldnt determine it via the known base image ids, this disregards differences between debian / ubuntu fedora / centos but we dont care about this for our purposes
  
    if flavour == nil
      puts "Determining flavour via which"

      if system("docker run --entrypoint=\/bin\/sh -it --rm #{image.id} -c \'which dpkg\'")
        flavour = "ubuntu"
      end
      if system("docker run --entrypoint=\/bin\/sh -it --rm #{image.id} -c \'which yum\'")
        flavour = "centos"
      end
      if system("docker run --entrypoint=\/bin\/sh -it --rm #{image.id} -c \'which apk\'")
        flavour = "alpine"
      end
    
    end
  
    return flavour
  
  end
  
  def list_packages(image_id, flavour)
    loaded_image = Docker::Image.get(image_id)
    puts loaded_image
    
    command = @docker_model.get_access_command(flavour) 
    puts "Trying to run"
    shellcommand = "docker run -e \"COLUMNS=300\" --entrypoint=\/bin\/sh -it --rm #{loaded_image.id} -c \'#{command}\'"
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