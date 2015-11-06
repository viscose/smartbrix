gem 'docker-api'

require 'docker'


class DockerAnalyser
  
  DOCKER_HOST="tcp://192.168.99.100:2376"  
  Docker.url = DOCKER_HOST
  
  ubuntu_command = 'dpkg -l'
  centos_command = 'yum list installed'
  debian_command = 'dpkg -l'
  alpine_command = 'apk --update info'
  
  ubuntu = ['a5a467fddcb8848a80942d0191134c925fa16ffa9655c540acd34284f4f6375d','38f2c35e1b5168a220026e2b873f349e0ac880f27e9bd337e672ad88734fa9c5']
  
    
  def determine_baseimage_flavour(image_id)
        image = Docker::Image.get(image_id)
        history = image.history
  end
  
  def list_packages(image, command)
    
  end
  
  
end

#docker rmi $(docker images | grep "^ubuntu" | awk '{print $3}') (single quotes!)]

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

base_image = Docker::Image.get('a5a467fddcb8')
container = base_image.run(['dpkg', '-l'])
container.attach(stream: true, stdout: true,
                 stderr: true, logs: true, tty: false) do |stream, chunk|
  puts("#{stream}: #{chunk}".strip())
end

container.delete()

# docker run -it --rm ubuntu:14.04 dpkg -l`

