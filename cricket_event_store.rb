require 'rubygems'
require 'bundler/setup'
require 'http_eventstore'
require_relative 'properties.rb'

# Set up EventStore
module CricketEventStore
  es_props = Properties.get("eventstore")
  @client = HttpEventstore::Connection.new do |config|
    config.endpoint = es_props[:ip]
    config.port = es_props[:port]
    config.page_size = '20'
  end
  @stream_name = es_props[:stream_name]

  def self.read_all_events()
    return @client.read_all_events_forward(@stream_name)
  end

  def self.append_to_stream(data)
   event_data = { event_type: "cricket_event",
                  data: data,
                  event_id: SecureRandom.uuid
                }
   begin
     @client.append_to_stream(@steam_name, event_data)
   rescue StandardError => e
     puts "Error #{e}"
   end
  end
end

