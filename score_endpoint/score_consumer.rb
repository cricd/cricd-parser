require 'rubygems'
require 'bundler/setup'
require 'json'
require 'date'
require 'sinatra'

require_relative '../cricket_event.rb'
require_relative '../cricket_score.rb'
require_relative '../cricket_event_store.rb'

set :port, 4567

module CricketScoreConsumer
# TODO: Implement match searching
  def self.get_score_at_over_ball(match_id, innings, over, ball)
  #Score for innings are going to be in a hash e.g. "1" => Innings_score
  score = {}
  # Read all the events from the stream
   events = CricketEventStore.read_all_events()
   events.each do |event|
    cricket_event = CricketEvent.new(event) 
    # Stop counting if we've reached our limit
    break if ((cricket_event.innings.to_i > innings.to_i) or\
              ((cricket_event.innings.to_i == innings.to_i) and (cricket_event.over.to_i > over.to_i)) or \
              ((cricket_event.innings.to_i == innings.to_i) and (cricket_event.over.to_i == over.to_i) and cricket_event.ball.to_i > ball.to_i))
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
   score.values.map! {|x| x.to_s}
   return score.to_json
end

  def self.get_score_at_datetime(match_id, datetime)
  #Score for innings are going to be in a hash e.g. "1" => Innings_score
    score = {}
    end_datetime = DateTime.iso8601(datetime)
  # Read all the events from the stream
  events = CricketEventStore.read_all_events()
  events.each do |event|
    cricket_event = CricketEvent.new(event) 
    # Stop counting if we've reached our limit
    current_datetime = DateTime.parse(cricket_event.timestamp)
    break if (current_datetime >= end_datetime)
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
   score.values.map! {|x| x.to_s}
   return score.to_json
end
end

