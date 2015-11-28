gem 'docker-api'

require 'docker'


require 'rest-client'
require './docker_model.rb'
require './docker_verification.rb'

require 'securerandom'


class DockerCompensation
  
  #DOCKER_HOST="tcp://0.0.0.0:2376"  
  #Docker.url = DOCKER_HOST
  

  @vulnerabilities = {}
  @sharp_packagelist = {}
  @fuzzy_packagelist = {}
  @image_name = nil
  @commands = []
  @docker_model = nil
  @startime=nil
  @pulltime=nil
  @processingtime=nil
  @endtime=nil
  @compenesation_variants= {}

  NONE_TAG = '<none>:<none>'
  NOP_PREFIX = '#(nop) '
  
  def initialize()
    @vulnerabilities = Hash.new
    @commands = Array.new
    @docker_model = DockerModel.new("base_image_ids.csv")
    @compenesation_variants = Hash.new
  end
  
  def get_commands()
    
    return @commands.reverse
    
  end
  
  def compensate(pull_command,id)
    @starttime=Time.now
    result = system("#{pull_command}:latest")
    if result == true
      @pulltime = Time.now - @starttime      
    else
      puts "Pull failed for #{pull_command}"
    end
    @pull_command = pull_command
    @image_name = pull_command.split(" ").last
    compensation_strategy = ENV["SB_C_STRAT"]
    image =nil
    if result 
    
      puts result

      # image = Docker::Image.get(@image_name)
      # call = "docker images -q #{@image_name}"
   #    image_id = sane_sys_call(call)
      image_id = `docker images -q #{@image_name}`.chomp

      # @image_history = image.history
      # @image_creation_date= `docker inspect -f '{{.Created}}' #{image.id}`
   #    @virtual_image_size= `docker inspect -f '{{.VirtualSize}}' #{image.id}`
   #     #docker inspect -f '{{.Created}}' d08adb7aae54
      puts "Analysing image with: #{image_id}"
      database_URL = ENV["SB_DBURL"]
      if compensation_strategy == "file"
        puts "File compensation"
        generate_docker_file(image_id)
       
        commands = get_commands()
        if commands.empty? == false
          result = auto_compensate_via_file(commands)
          if result == true
            elapsed_time = (Time.now - @starttime)
        
            response = RestClient.post "http://admin:admin@#{database_URL}/analytics/compensations",{ 'image_name' => @image_name,'image_id' => image_id, 'pull_command' => @pull_command, 'runtime_total' => elapsed_time, 'pull_time' => @pulltime, 'timestamp' => "#{DateTime.now.to_s}", 'object_id' => id, 'compensations' => @compenesation_variants}.to_json, :content_type => :json, :accept => :json
          #RestClient.post "http://admin:admin@192.168.99.100:8080/analytics/vulnerabilities",{ 'image_id' => 1}.to_json, :content_type => :json, :accept => :json
            puts response
          
          else
            puts "Couldn not autocompensate image #{@image_name}"
          end
        else
          puts "Couldn not generate Dockerfile for #{@image_name}"
        end
      end
      
      if compensation_strategy == "image"
        # generate_docker_file(image_id)
#         commands = get_commands()
        puts "Image Compensation"
        
        flavour = determine_baseimage_flavour_via_image_id(image_id)
        # Upgrade
        # Generate uniquid
        compensated_id = SecureRandom.hex
        if(flavour == "ubuntu")
          puts "Trying to run ubuntu compensation"
          container_id = `docker run --name=#{compensated_id} --entrypoint=\/bin\/sh -it #{image_id} -c \'apt-get update && apt-get -y upgrade\'`.chomp
        end
        if(flavour == "alpine")
           container_id = `docker run --name=#{compensated_id} --entrypoint=\/bin\/sh -it #{image_id} -c \'apk --update upgrade\'`.chomp
        end
        if(flavour == "fedora")
          container_id = `docker run --name=#{compensated_id} --entrypoint=\/bin\/sh -it #{image_id} -c \'yum -y update\'`.chomp
        end
        entry_point = `docker inspect -f "{{ .Config.Entrypoint }}" #{image_id}`.chomp
        puts "Received EP: #{entry_point}}"
        if entry_point == "<nil>"
          entry_point ="[]"
        else
          entry_point = entry_point[1..-2]
        end
        command = `docker inspect -f "{{.Config.Cmd}}" #{image_id}`.chomp
        puts "Received Command: #{command}"
        command = command[1..-2]
        if command == "nil"
          command ="[]"
        else
          #Re marshall stuff
          #captures = Hash[ matches.names.zip( matches.captures ) 
          matches = /(\w+)/.match(command)
        
          matches.captures.each do |match|
            command.sub!(match,"\"#{match}\"")
          
          end
        end
        puts command
        
        
        #docker commit -c 'ENTRYPOINT []' -c 'CMD ["/bin/bash"]' abbdae181e21 wurst12333
        puts "Committing image with #{entry_point} and #{command}"
        
        compensated_image_id = `docker commit -c 'ENTRYPOINT #{entry_point}' -c 'CMD #{command}'  #{compensated_id} compensated/#{@image_name}:#{compensated_id}`.chomp
        # removed = `docker rm #{compensated_id}`
        puts "Successfully compensated #{compensated_image_id} for #{@image_name}"
        elapsed_time = (Time.now - @starttime)*1000
        verification = DockerVerification.new
        verification.analyse_image_id(compensated_image_id,flavour,@image_name,object_id)
        puts "Finished verification"
        response = RestClient.post "http://admin:admin@#{database_URL}/analytics/compensations",{ 'image_name' => @image_name,'image_id' => image_id, 'pull_command' => @pull_command, 'runtime_total' => elapsed_time,'pull_time' => @pulltime,'timestamp' => "#{DateTime.now.to_s}", 'object_id' => id, "compensated_image_id" => compensated_image_id, 'compensations' => "image"}.to_json, :content_type => :json, :accept => :json
        puts response
     
        
      end
 
      
    
    else
      puts "Could not pull image #{@image_name}:latest"
    end 
  
  end

  
  def determine_baseimage_flavour_via_image_id(image_id)
    
    flavour = nil
  
    puts "Determining flavour via which"
    
    # command = "docker run --entrypoint=\/bin\/sh -it --rm #{image_id} -c \'which dpkg\'"
#     puts command

    if system("docker run --entrypoint=\/bin\/sh -it --rm #{image_id} -c \'which dpkg\'")
      flavour = "ubuntu"
    end
    if system("docker run --entrypoint=\/bin\/sh -it --rm #{image_id} -c \'which yum\'")
      flavour = "centos"
    end
    if system("docker run --entrypoint=\/bin\/sh -it --rm #{image_id} -c \'which apk\'")
      flavour = "alpine"
    end

    puts "Found #{flavour}"
    return flavour
  
  end
  
  
  def determine_base_image_flavour(commands)
    
    flavour = nil
    run_commands = commands.select{|command| command.start_with?("RUN")}
    
    run_commands.each do |command|
      
      if(command.include?("apk"))
        flavour = "alpine"
      end
      if(command.include?("yum"))
        flavour = "fedora"
      end
      if(command.include?("apt"))
        flavour = "ubuntu"
      end
      
    end
    
    puts "Found the following base flavour:#{flavour}"
    return flavour
    
  end
  
  def build_image_from_commands()
    File.open("./dockerfiles/Dockerfile","w+") do |f|
      f.puts(@commands.reverse)
    end
    
    
    
    # Docker::Image.build(@commands.reverse.to_s) # do |v|
 #      if (log = JSON.parse(v)) && log.has_key?("stream")
 #        $stdout.puts log["stream"]
 #      end
 #    end
  end
  
  
  def auto_compensate_via_file(commands)
    
    variant_a = nil
    variant_b = nil
   
    
    flavour = determine_base_image_flavour(commands)
    if(flavour !=nil)
      if flavour == "ubuntu"
        variant_a = commands.map(&:clone)
        variant_b = commands.map(&:clone)
        
        
        variant_a[0]="FROM #{flavour}"
        variant_b[0]="FROM debian"
      end
      if flavour == "fedora"
        variant_a = commands.map(&:clone)
        variant_b = commands.map(&:clone)
        
        
        variant_a[0]="FROM #{flavour}"
        variant_b[0]="FROM centos"
      end
      
      variant_a = commands.map(&:clone)
      variant_a[0]="FROM #{flavour}"
      
    else
      return false
    end
    
    #Check if there is a copy command
    copy_index = variant_a.index{|x| x.start_with?("COPY")}
    if copy_index != nil
      return false
    end
    
    #Check if there is another add
    add_index = variant_a.index{|x| x.start_with?("ADD")}
    if add_index != nil
      return false
    end
    
    @compenesation_variants["variant_a"] = variant_a
    
    if variant_b != nil
      @compenesation_variants["variant_b"] = variant_b
    end
    
  
    
    # if(store = "file")
    #
    #   File.open("./dockerfiles/Dockerfile_variant_a","w+") do |f|
    #     f.puts(variant_a)
    #   end
    #
    #   if variant_b != nil
    #     File.open("./dockerfiles/Dockerfile_variant_b","w+") do |f|
    #       f.puts(variant_b)
    #     end
    #   end
    # else
    #
    #
    # end
    return true
    
  end
  
  # Adapted from CenturyLinks
  def generate_docker_file(image_id)
    tags = Docker::Image.all.each_with_object({}) do |image, hsh|
      tag = image.info['RepoTags'].first
      hsh[image.id] = tag unless tag == NONE_TAG
    end

    loop do
      # TODO update this part
      # If the current ID has a tag, render FROM instruction and break
      # (unless this is the first command)
      # if @commands && tags.key?(image_id)
 #        @commands << "FROM #{tags[image_id]}"
 #        break
 #      end

      begin
        image = Docker::Image.get(image_id)
      rescue Docker::Error::NotFoundError
        abort('Error: specified image tag or ID could not be found')
      end

      cmd = image.info['ContainerConfig']['Cmd']

      if cmd && cmd.size == 3
        cmd = cmd.last

        if cmd.start_with?(NOP_PREFIX)
          @commands << cmd.split(NOP_PREFIX).last
        else
          @commands << "RUN #{cmd}".squeeze(' ')
        end
      end

      image_id = image.info['Parent']
      break if image_id == ''
    end
    return @commands
  end
  
  
end

# "puts starting local compensation"
# compensation = DockerCompensation.new
# compensation.compensate("docker pull cantino/huginn","123")
# compensation.generate_docker_file('6ec3b2e516f4')
# puts compensation.get_commands()
# puts compensation.auto_compensate_image(compensation.get_commands())
# puts "Trying to build an image"
# compensation.determine_base_image_flavour(compensation.get_commands())
# compensation.build_image_from_commands
# test = DockerModel.new("base_image_ids.csv")
# puts test.determine_flavour('689d21049d4e')

