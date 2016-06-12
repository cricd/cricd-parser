require 'json'
require 'logger'

module Properties
  @logger = Logger.new(STDOUT)
  @file_path="./application.json"
     begin
       file = File.read("#{@file_path}")
     rescue IOError => e
       @logger.fatal("Unable to find properties file at #{@file_path} #{e}")
       exit
     rescue Errno::ENOENT => e
       @logger.fatal("Unable to load properties file at #{@file_path} #{e}")
       exit
     end
       @properties = JSON.parse(file, :symbolize_names => true)


   def self.get(property_type)
     if @properties.key?(property_type.to_sym)
       return @properties[property_type.to_sym]
     else
       return nil
     end
   end
end
