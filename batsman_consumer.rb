
require 'rubygems'
require 'bundler/setup'

require 'yaml'
require 'securerandom'
require 'date'
require 'json'
require 'http_eventstore'
require 'pp'
require_relative 'properties.rb'

$wickets = ["bowled", "caught","caughtAndBowled", "lbw", "stumped", "run out", "retiredHurt", "hitWicket", "obstructingTheField", "hitTheBallWwice", "handledTheBall", "timedOut"]

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

# Create a struct to define what a batsman score looks like
Struct.new("Batsman_score", :name, :runs, :balls, :wicket, :strike_rate)

# Create an array for each batsmans score
batsmen = {}
 
events.each do |event|
  batsman = event.data["batsmen"]["striker"]
  # If it's a wicket update how he got out
  if $wickets.include?(event["data"]["eventType"])
    if batsman.has_key?(batsman["id"])
      batsmen[batsman["id"]].wicket = event["data"]["eventType"]
    else
      batsmen[batsman["id"]] = Struct::Batsman_score.new(
        event["data"]["batsmen"]["striker"]["name"],
        0,
        1,
        event["data"]["eventType"],
        0
      )
    end
  else
    # If we've seen this batsman before we're going to add to his stats
    if batsmen.has_key?(batsman["id"])
      batsmen[batsman["id"]].runs += event["data"]["runs"].to_i
      batsmen[batsman["id"]].balls += 1 
      batsmen[batsman["id"]].strike_rate =  100 * batsmen[batsman["id"]].runs.to_f / batsmen[batsman["id"]].balls.to_f 
    # Otherwise we're going to create the score
    else
      batsmen[batsman["id"]] = Struct::Batsman_score.new(
        event["data"]["batsmen"]["striker"]["name"],
        event["data"]["runs"].to_i,
        1,
        "not out",
        100 * (event["data"]["runs"].to_f)
      )
    end
  end
end

batsmen.each do |key,value|
  puts "#{value.name} scored #{value.runs} off #{value.balls} with a strike rate #{value.strike_rate.round(2)} and was #{value.wicket}"
end






