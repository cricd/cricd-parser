
require 'rubygems'
require 'bundler/setup'

require 'yaml'
require 'securerandom'
require 'date'
require 'json'
require 'http_eventstore'
require 'pp'
require_relative 'properties.rb'

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
Struct.new("Batsman_score", :runs, :balls, :strike_rate)

# Create an array for each batsmans score
batsmen = []


 
events.each do |event|
  pp event
end






