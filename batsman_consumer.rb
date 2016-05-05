
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


class CricketBatsmanScore
  def initialize(id, name)
    @id = id
    @name = name
    @runs = 0
    @balls = 0
    @wicket = "not out"
    @strike_rate = 0
  end

  def update(event)
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


# Get properties
properties = Properties.new
all_properties = properties.get_properties()

# Set up EventStore
client = HttpEventstore::Connection.new do |config|
  config.endpoint = all_properties["eventstore"]["ip"]
  config.port = all_properties["eventstore"]["port"]
  config.page_size = '20'
end
stream_name = all_properties["eventstore"]["stream_name"]

# Read all the events from the stream
events = client.read_all_events_forward(stream_name)

# Create an array for each batsmans score
batsmen = {}
events.each do |event|
  cricket_event = CricketEvent.new(
    event.data["match"],
    event.data["eventType"],
    event.data["timestamp"],
    event.data["ball"]["battingTeam"],
    event.data["ball"]["fieldingTeam"],
    event.data["ball"]["innings"],
    event.data["ball"]["over"],
    event.data["ball"]["ball"],
    event.data["runs"],
    event.data["batsmen"]["striker"],
    event.data["batsmen"]["nonStriker"],
    event.data["bowler"],
    event.data["fielder"]
  )

  batsman = event.data["batsmen"]["striker"]
  unless batsmen.has_key?(batsman["id"])
    batsmen[batsman["id"]] = CricketBatsmanScore.new(
      batsman["id"],
      batsman["name"]
    )
  end
  batsmen[batsman["id"]].update(cricket_event)

end

batsmen.each do |key, value|
  puts value.to_s
end






