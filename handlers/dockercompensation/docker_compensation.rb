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
  
  def generate_docker_file(image_id)
    tags = Docker::Image.all.each_with_object({}) do |image, hsh|
      tag = image.info['RepoTags'].first
      hsh[image.id] = tag unless tag == NONE_TAG
    end

    loop do
      # If the current ID has a tag, render FROM instruction and break
      # (unless this is the first command)
      # if !options[:full] && @commands && tags.key?(image_id)
      #   @commands << "FROM #{tags[image_id]}"
      #   break
      # end

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
puts "Trying to build an image" 
compensation.build_image_from_commands
test = DockerModel.new("base_image_ids.csv")
puts test.determine_flavour('3037fa9e903e9ae5338ac1dd3adf8d3ff2d165d3a9b550c64879651582c77dc4')

