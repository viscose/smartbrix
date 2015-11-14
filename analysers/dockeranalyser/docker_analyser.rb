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
  
  def initialize()
    @docker_model = DockerModel.new("base_image_ids.csv")
    @vulnerabilities = Hash.new
  end
  
  def analyse(package_name,pull_command)
    result = `#{pull_command}`
    
    @image_name = pull_command.split(" ").last
     
    if result 
      
      image_id = Docker::Image.get(@image_name)
      return analyse_image_id(image_id.id)
      
    end
      
    # should clean up as well
   
    
  end
  
  def analyse_image_id(test_id)
    
    flavour = determine_baseimage_flavour(test_id)
    puts flavour
    
    if flavour 
      puts "Got flavour determining command"
      command = @docker_model.get_access_command(flavour)
      puts "got command:#{command}"
      packages = list_packages(test_id,flavour)
      
      ##return analyse_sharp(packages) && analyse_fuzzy(packages)
      result = analyse_fuzzy(packages)
      
      if result != nil
        # Store them into the database
      
        database_URL = ENV["SB_DBURL"]
        url = "http://admin:admin@#{database_URL}/analytics/vulnerabilities"
        puts url
        response = RestClient.post "http://admin:admin@#{database_URL}/analytics/vulnerabilities",{ 'image_name' => @image_name,'image_id' => test_id, 'vulnerabilities' => @vulnerabilities }.to_json, :content_type => :json, :accept => :json
        #RestClient.post "http://admin:admin@192.168.99.100:8080/analytics/vulnerabilities",{ 'image_id' => 1}.to_json, :content_type => :json, :accept => :json
        puts response
          
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
  
  
  def analyse_fuzzy(packages)
    
    packages = packages.group_by{|x| x[0].split("-").first}.select { |k,v| v.length > 1 }
    @fuzzy_packagelist = packages
    analyse_packages(packages)
    
  end
  
  def analyse_packages(packages)
    found = false
    
    packages.each do |name,version|
      
      cveurl = ENV["SB_CVEHUB"]
      # response = RestClient.get 'http://0.0.0.0:8000/cves', {:params => {'name' => name}}#, 'version' => version}}
      
      #(\d+\.)?(\d+\.)?(\*|\d+)
      
      # Parse version
      # First we check wheter it is an aggregated package or not then we apply some basic regex
      if version.is_a?(Array)
        # We just take the first version we find
        checking = version.flatten
        checking.each do |candidate|
          version = candidate.match(/(\d+\.)?(\d+\.)?(\*|\d+)/)
          if version != nil
            version = version.to_s
            break
          end
          
          
        end
        
      else
        version = version.match(/(\d+\.)?(\d+\.)?(\*|\d+)/).to_s
      end
      
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


# Old container code for docker-api currently not working. 

#docker rmi $(docker images | grep "^ubuntu" | awk '{print $3}') (single quotes!)]
# container.exec(['dpkg -l']) { |stream, chunk| puts "#{stream}: #{chunk}" }
# container.delete()

#
# image = Docker::Image.create('fromImage' => 'ubuntu:14.04')
#
# container = Docker::Container.create('Image' => 'ubuntu:14.04')
# container.exec('dpkg -l')
#
# command = ["bash", "-c", "if [ -t 1 ]; then echo -n \"I'm a TTY!\"; fi"]
# container = Docker::Container.create('Image' => 'ubuntu:14.04', 'Cmd' => command, 'Tty' => true)
# container.tap(&:start).attach(:tty => true)
#
# image.run('dpkg -l')

# base_image = Docker::Image.get('a5a467fddcb8')
# container = base_image.run(['dpkg', '-l'])
# container.attach(stream: true, stdout: true,
#                  stderr: true, logs: true, tty: false) do |stream, chunk|
#   puts("#{stream}: #{chunk}".strip())
# end
#
# container.delete()


# def list_packages(image, command)
#   loaded_image = Docker::Image.get('a5a467fddcb8')
#   puts loaded_image
#   container = loaded_image.run(['dpkg', '-l'])
#   puts container
#   container.exec(['dpkg -l']) { |stream, chunk| puts "#{stream}: #{chunk}" }
#   container.delete()
#   # container = loaded_image.run(['dpkg', '-l'])
#   container.start do
#     container.exec(['dpkg -l'])
#     container.attach(stream: true, stdout: true,
#                      stderr: true, logs: true, tty: false) do |stream, chunk|
#       puts("#{stream}: #{chunk}".strip())
#     end
#   end
#
# end

# docker run -it --rm ubuntu:14.04 dpkg -l`
# output = `docker run -it --rm ubuntu:14.04 dpkg -l`
