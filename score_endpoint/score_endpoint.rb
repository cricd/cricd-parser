require 'sinatra'
require 'json'
require 'date'
require_relative '../cricket_event.rb'
require_relative '../cricket_score.rb'
require_relative '../cricket_event_store.rb'



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

# def coerce(param, type)
#   begin
#     return nil if param.nil?
#     return param if (param.is_a?(type) rescue false)
#     return Integer(param) if type == Integer
#     return Float(param) if type == Float
#     return String(param) if type == String
#     return Date.parse(param) if type == Date
#     return Time.parse(param) if type == Time
#     return DateTime.parse(param) if type == DateTime
#     return nil
#   rescue ArgumentError
#      puts "'#{param}' is not a valid #{type}"
#   end
# end

# def check_required_parameters(params, possible_params)
#   # Check all the parameters
#   required_params_exist = required_params.map { |x| params.include?(x) ? true : x}
#   unless required_params_exist.all? { |param| param == true }
#     puts "Missing #{required_params_exist} parameter(s)"
#     return false
#   end
#   return true
# end

# def check_parameter_types(params, possible_params)
#   correct_param_values = params.map {|key, value| coerce(value, possible_params[key][:type]) ? true : key}
#   unless correct_param_values.all? { |param| param == true }
#     puts "Parameter#{correct_param_values.delete_if{ |x| x==true }} is not the right type"
#     return false
#   end
#   return true
# end

# def check_parameter_values(params, possible_params)
#   # Check all the min/max
#   min_values = possible_params.map { |key, value| value[:min] ? key : nil }.compact
#   max_values = possible_params.map { |key, value| value[:max] ? key : nil }.compact

#   min_values_satisfied = min_values.map { |key| params[key] > possible_params[key][:min]}.all?
#   max_values_satisfied = max_values.map { |key| params[key] > possible_params[key][:max]}.all?
#   unless (max_values_satisfied and min_values_satisfied)
#     puts "Not all maximum values satisfied"
#     return false
#   end
#   return true
# end

# RESTful service that allows you to find the score
# Requires:
# - match ID (final/current score)
# - over/ball (at a ball)
# - date/time (at a particular time?)

  # GET /score?match_id=123
  # GET /score?match_id=123&datetime=2015-01-01
  # GET /score?match_id=123&over=12
  # GET /score?match_id=123&ball=3
  # GET /score?match_id=123&over=12&ball=3
get '/score' do

  possible_params = {
    "match_id" => {:type => Integer, :required => true, :min => nil, :max => nil},
    "datetime" => {:type => DateTime, :required => false, :min => nil, :max => nil},
    "innings" => {:type => Integer, :required => false, :min => 1, :max => nil},
    "over" => {:type => Integer, :required => false, :min => nil, :max => nil},
    "ball" => {:type => Integer, :required => false, :min => 0, :max => 5}
  }


  # if (required_params and correct_param_types and correct_param_values)
  #   if params.key?("over")
  #    result = CricketScoreConsumer.get_score_at_over_ball(params["match_id"], params["innings"], params["over"], params["ball"]) 
  #   else
  #    result = CricketScoreConsumer.get_score_at_datetime(params["match_id"], params["datetime"]) 
  #   end
  # end

  return "result"
end

