require 'json'

module Properties
   @file_path="./application.json"
   if File.exists?(@file_path)
     file = File.read("#{@file_path}")
     @properties = JSON.parse(file, :symbolize_names => true)
   else
     @properties = nil
   end

   def self.get(property_type)
     if @properties.key?(property_type.to_sym)
       return @properties[property_type.to_sym]
     else
       return nil
     end
   end
end
