gem 'docker-api'

require 'docker'
require './docker_model.rb'


class DockerAnalyser
  
  DOCKER_HOST="tcp://192.168.99.100:2376"  
  Docker.url = DOCKER_HOST
  
  @docker_model = nil
  
  def initialize()
    @docker_model = DockerModel.new("base_image_ids.csv")
  end
  
    
  def determine_baseimage_flavour(image_id)
        image = Docker::Image.get(image_id)
        history = image.history.reverse
        
        flavour = nil
        
        history.each do |entry|
          puts entry["Id"]      
          
          flavour = @docker_model.determine_flavour("#{entry["Id"]}")
          if flavour != nil
            break;
          end
          
        end
        
        return flavour
        
  end
  
  def list_packages(image, command)
    loaded_image = Docker::Image.get(image)
    puts loaded_image

    result = `docker run -it --rm #{loaded_image.id} #{command}`
    
    
    result_linewise = result.split("\n").reject{|item| !item.start_with?("ii")}.map{|item| item.gsub!(/\s+/, ',')}
    
    packages = {}
    puts result_linewise
    result_linewise.each do |package|
      
      package_elements = package.split(",")
      
      puts package_elements
    
      packages[package_elements[1]]=package_elements[2]
      
    end
    
    return packages
    
  end
  
  
  def start()
    test_id = '5eb72b199374'
    
    flavour = determine_baseimage_flavour(test_id)
    puts flavour
    
    if flavour 
      puts "Got flavour determining command"
      command = @docker_model.get_access_command(flavour)
      puts "got command:#{command}"
      list_packages(test_id,command)
    end
    
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
