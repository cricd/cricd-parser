require 'rubygems'
require 'bundler/setup'
require 'http_eventstore'
require 'logger'


# Set up EventStore
module CricketEventStore
  settings = {
    :ip => ENV["EVENTSTORE_IP"].nil? ? "localhost" : ENV["EVENTSTORE_IP"],
    :port => ENV["EVENTSTORE_PORT"].nil? ? "2113" : ENV["EVENTSTORE_PORT"],
    :stream_name => ENV["EVENTSTORE_STREAM_NAME"].nil? ? "cricket_events_v1" : ENV["EVENTSTORE_STREAM_NAME"]
  }


  @logger = Logger.new(STDOUT)
  @client = HttpEventstore::Connection.new do |config|
    config.endpoint = settings[:ip]
    config.port = settings[:port]
    config.page_size = '20'
  end
  @stream_name = settings[:stream_name]

  def self.read_all_events()
    begin
      all_events = @client.read_all_events_forward(@stream_name)
    rescue StandardError => e
      @logger.error("Failed to read events from EventStore #{e}")
    end
    return all_events.nil? ? nil : all_events
  end

  def self.append_to_stream(data)
   event_data = { event_type: "cricket_event",
                  data: data,
                  event_id: SecureRandom.uuid
                }
   begin
     @client.append_to_stream(@stream_name, event_data)
   rescue StandardError => e
     @logger.error("Failed to push event to EventStore - #{e}")
   end
  end
end

