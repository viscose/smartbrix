gem 'docker-api'

require 'docker'


require 'rest-client'
require './docker_model.rb'


class DockerCompensation
  
  #DOCKER_HOST="tcp://0.0.0.0:2376"  
  #Docker.url = DOCKER_HOST
  

  @vulnerabilities = {}
  @sharp_packagelist = {}
  @fuzzy_packagelist = {}
  @image_name = nil
  @commands = []
  @docker_model = nil

  NONE_TAG = '<none>:<none>'
  NOP_PREFIX = '#(nop) '
  
  def initialize()
    @vulnerabilities = Hash.new
    @commands = Array.new
    @docker_model = DockerModel.new("base_image_ids.csv")
  end
  
  def get_commands()
    
    return @commands.reverse
    
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
  
  
  def auto_compensate_image(commands)
    
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
    
    File.open("./dockerfiles/Dockerfile_variant_a","w+") do |f|
      f.puts(variant_a)
    end
    
    if variant_b != nil
      File.open("./dockerfiles/Dockerfile_variant_b","w+") do |f|
        f.puts(variant_b)
      end
    end
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
  end
end

compensation = DockerCompensation.new
compensation.generate_docker_file('6ec3b2e516f4')
puts compensation.get_commands()
puts compensation.auto_compensate_image(compensation.get_commands())
puts "Trying to build an image" 
compensation.determine_base_image_flavour(compensation.get_commands())
# compensation.build_image_from_commands
# test = DockerModel.new("base_image_ids.csv")
# puts test.determine_flavour('689d21049d4e')

