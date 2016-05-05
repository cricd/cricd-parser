require 'rubygems'
require 'bundler/setup'

require 'yaml'
require 'securerandom'
require 'date'
require 'json'
require 'http_eventstore'
require 'pp'
require_relative 'properties.rb'

# Wickets
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

# Create a struct to define what a score looks like
Struct.new("Innings_score", :runs, :over, :ball, :wickets)

# Score for innings are going to be in a hash e.g. "1" => Innings_score
score = {}

events.each do |event|
  current_innings = event["data"]["ball"]["innings"]
  # If we've got some data on this innings
  if score.has_key?(current_innings)
    score[current_innings].runs += event["data"]["runs"].to_i
    score[current_innings].over = event["data"]["ball"]["over"].to_i
    score[current_innings].ball = event["data"]["ball"]["ball"].to_i
    # If it's a wicket eventType then add to the wickets
    if $wickets.include?(event["data"]["eventType"])
      score[current_innings].wickets += 1
    end
    # Otherwise create a new record for the innings
  else
    score[current_innings] = Struct::Innings_score.new(
      event["data"]["runs"].to_i,
      event["data"]["ball"]["over"].to_i,
      event["data"]["ball"]["ball"].to_i)
    # If by some crazy chance the first ball is a wicket, add to wickets
    if $wickets.include?(event["data"]["eventType"])
      score[current_innings].wickets = 1
    else
      score[current_innings].wickets = 0
    end
  end
end
score.each do |key,value|
  puts "#{value.runs}/#{value.wickets} off #{value.over}.#{value.ball}"
end
