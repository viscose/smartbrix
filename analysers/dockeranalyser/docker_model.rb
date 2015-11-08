require 'csv'

class DockerModel
  
  @@base_images = {}
  
  @@ubuntu_command = 'dpkg -l'
  @@centos_command = 'yum list installed'
  @@debian_command = 'dpkg -l'
  @@alpine_command = 'apk --update info'
  
  @@base_image_flavours = {"ubuntu" => @@ubuntu_command,"centos" => @@centos_command, "debian" => @@debian_command, "fedora" => @@centos_command, "alpine" => @@alpine_command}
  
  def initialize(args)
    file = args
    puts file
    CSV.foreach(file) do |row|
      key = row[2]
      @@base_images[key]=row[0]
      
    end
  end
  
  def determine_flavour(image_id)
    flavour = @@base_images[image_id]    
  end
  
  def get_access_command(flavour)
    @@base_image_flavours[flavour]
  end
  
  def print_base_images()
    @@base_images.each do |key, value|
      puts "#{key}:#{value}"
    end
  end
  
  
end