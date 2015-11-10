gem 'docker-api'

require 'docker'
require './docker_model.rb'

require 'rest-client'


class DockerAnalyser
  
  DOCKER_HOST="tcp://192.168.99.100:2376"  
  Docker.url = DOCKER_HOST
  
  @docker_model = nil
  @vulnerabilities = {}
  @sharp_packagelist = {}
  @fuzzy_packagelist = {}
  
  def initialize()
    @docker_model = DockerModel.new("base_image_ids.csv")
    @vulnerabilities = Hash.new
  end
  
  def analyse(test_id)
    flavour = determine_baseimage_flavour(test_id)
    puts flavour
    
    if flavour 
      puts "Got flavour determining command"
      command = @docker_model.get_access_command(flavour)
      puts "got command:#{command}"
      packages = list_packages(test_id,flavour)
      
      ##return analyse_sharp(packages) && analyse_fuzzy(packages)
      return analyse_fuzzy(packages)
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
  
    #result.group_by{|x| x[0].split("-").first}.select { |k,v| v.length > 1 }
  
  ## Currently only a test method. 
  def test()
    test_id = '8c100304a4f9'
    
    if analyse(test_id) 
      puts "HEUREKA"
      
      @vulnerabilities.each do |name, vulnerability|
        puts "Found vulnerability for #{name}"
        puts "Specifics are"
        
        vulnerability = JSON.parse(vulnerability)
        vulnerability.each do |details|
          puts "For package #{details["vulnerable_software"]} with the following #{details["summary"]}"
        end
        

        puts @fuzzy_packagelist[name]
        
        
      end
    else
      puts "SHARP"
      puts @sharp_packagelist
      puts "FUZZY"
      puts @fuzzy_packagelist
      
    end
    
    return true
    
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
      
      # TODO this needs to be injected of course
      response = RestClient.get 'http://0.0.0.0:8000/cves', {:params => {'name' => name}}#, 'version' => version}}
      
      
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
