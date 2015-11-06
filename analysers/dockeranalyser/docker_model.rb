require 'csv'

class DockerModel
  
  @@base_images = {}
  
  def initialize(args)
    file = args
    puts file
    CSV.foreach(file) do |row|
      key = row[2]
      @@base_images[key]=row[0]
      
    end
    puts @@base_images.inspect
  end
  
  
end