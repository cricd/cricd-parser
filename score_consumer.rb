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

class CricketScore
  def initialize(runs, over, ball, wickets)
    @runs = runs
    @over = over
    @ball = ball
    @wickets = wickets
  end

  def update_from_event(event)
    @runs += event.instance_variable_get(:@runs).to_i
    @over = event.instance_variable_get(:@over).to_i
    @ball = event.instance_variable_get(:@ball).to_i
    if event.is_wicket?()
      @wickets += 1
    end
  end

  def to_s()
    puts "#{@runs}/#{@wickets} off #{@over}.#{@ball}"
  end

end

# Set up EventStore
es_props = Properties.get("eventstore")
client = HttpEventstore::Connection.new do |config|
  config.endpoint = es_props["ip"]
  config.port = es_props["port"]
  config.page_size = '20'
end
stream_name = es_props["stream_name"]

# Read all the events from the stream
events = client.read_all_events_forward(stream_name)

# Score for innings are going to be in a hash e.g. "1" => Innings_score
score = {}

events.each do |event|
 cricket_event = CricketEvent.new(event) 
  current_innings = event["data"]["ball"]["innings"]
  # If we've got some data on this innings
  if score.has_key?(current_innings)
    score[current_innings].update_from_event(cricket_event)
  else
    score[current_innings] = CricketScore.new(
      event["data"]["runs"].to_i,
      event["data"]["ball"]["over"].to_i,
      event["data"]["ball"]["ball"].to_i,
      cricket_event.is_wicket?() ? 1 : 0)
  end
end

score.each do |key,value|
  puts value.to_s()
end
