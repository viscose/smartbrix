

# Dir["./analysers/*.rb"].each {|file| require file }

# require '../lib/datastore.rb'

require 'rest-client'

class SmartbrixManager 
  
  
  def initialize(endpoint)
    @endpoint = endpoint
    # @dependency_manager = "http://localhost:7000"
  end
  #
  #
  # def move (tu_name,destination_is_name)
  # #Find TU // Consolidated for testing purposes
  # puts "Attempting to move #{tu_name} to #{destination_is_name}"
  # tu = lookup_tu(tu_name)
  # puts "Found TU #{tu}"
  # #Find IS
  # is = lookup_is(destination_is_name)
  # puts "Found IS #{is}"
  # #Find DU
  # #Check if there is a DU with IS and TU
  # du = lookup_du(tu,is)
  # puts "Found DU #{du}"
  #
  #
  # du_name = du.first["name"]
  # is_name = is["name"]
  # tu_name = tu["name"]
  #
  # puts "Resolving dependencies for #{tu_name},#{is_name} #{du_name}"
  # #If nothing is being found the Analyzers come to play
  #
  # #Resolve dependencies.
  # #response = RestClient.get "#{@dependency_manager}/resolve?tu=#{tu['name']}&du=#{du['name']}&is=#{is['name']}"
  #
  # response = RestClient.get "#{@dependency_manager}/resolve", {:params => {:tu => tu_name, :du => du_name, :is => is_name}}
  #
  #
  # #Find DI
  # #di = lookup_di("")
  #
  #
  # #Deploy
  #
  #
  #
  # end
  #
  #
  #
  # def lookup_tu(tu)
  #   response = RestClient.get "#{@endpoint}/tu?name=#{tu}"
  #   #Some sanity checks
  #   JSON.parse(response)
  # end
  #
  # def lookup_is(is)
  #   response = RestClient.get "#{@endpoint}/is?name=#{is}"
  #   JSON.parse(response)
  # end
  #
  # def lookup_du(tu,is)
  #   # Basic mechanism needs to be extended with smarter search
  #   # features
  #
  #   response = RestClient.get "#{@endpoint}/du"
  #   result = JSON.parse(response)
  #   applicable_units = []
  #   if(!result.empty?)
  #     result.each do |deployment_unit_name|
  #       #Check if the unit applies
  #       puts deployment_unit_name
  #       response = RestClient.get "#{@endpoint}/du?name=#{deployment_unit_name.gsub(/\s+/, "")}"
  #       du_candidate = JSON.parse(response)
  #       puts du_candidate
  #       if(!du_candidate.empty?)
  #       #Check if it contains the tu
  #         found = du_candidate["technicalUnits"].any?{|unit|  unit["name"] == tu["name"]}
  #         puts "Technical Unit found:#{found}"
  #         if(found)
  #           #Check if is is also correct
  #           #found = du_candidate["infra"]
  #           if(found)
  #             applicable_units << du_candidate
  #           end
  #           # Add it to the applicable units
  #         end
  #       end
  #
  #     end
  #   end
  #   return applicable_units
  # end
  #
  #
  # def lookup_di(di)
  #   response = RestClient.get "#{@endpoint}/di?name=#{di}"
  # end
end