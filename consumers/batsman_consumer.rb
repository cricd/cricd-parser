
require 'rubygems'
require 'bundler/setup'

require 'yaml'
require 'securerandom'
require 'date'
require 'json'
require 'http_eventstore'
require 'pp'
require_relative 'properties.rb'
require_relative 'cricket_event.rb'

#TODO fix the wide and noball rules

class CricketBatsmanScore
  def initialize(id, name)
    @id = id
    @name = name
    @runs = 0
    @balls = 0
    @wicket = "not out"
    @strike_rate = 0
  end

  def update_from_event(event)
    if event.is_wicket?
      @wicket = event.instance_variable_get(:@type)
    else
      @runs += event.instance_variable_get(:@runs).to_i
      @balls += event.instance_variable_get(:@ball).to_i
      @strike_rate = 100* @runs.to_f / @balls.to_f
    end
  end

  def to_s()
   puts "#{@name} scored #{@runs} off #{@balls} with a strike rate of #{@strike_rate.round(2)} and was #{@wicket}"
  end

end



# Set up EventStore
es_config = Properties.get("eventstore")
client = HttpEventstore::Connection.new do |config|
  config.endpoint = es_config["ip"]
  config.port = es_config["port"]
  config.page_size = '20'
end
stream_name = es_config["stream_name"]

# Read all the events from the stream
events = client.read_all_events_forward(stream_name)

# Create an array for each batsmans score
batsmen = {}
events.each do |event|
  cricket_event = CricketEvent.new(event)
  batsman = event.data["batsmen"]["striker"]
  # Create the batsman in the hash if it doesn't exit
  unless batsmen.has_key?(batsman["id"])
    batsmen[batsman["id"]] = CricketBatsmanScore.new(
      batsman["id"],
      batsman["name"])
  end
  # Update the bastman score
  batsmen[batsman["id"]].update_from_event(cricket_event)

end

# Print to screen
batsmen.each do |key, batsman_score|
  puts batsman_score.to_s
end






