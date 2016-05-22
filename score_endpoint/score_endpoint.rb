require 'sinatra'
require 'json'
#require_relative 'score_consumer.rb'


def coerce(param, type)
  begin
    return nil if param.nil?
    return param if (param.is_a?(type) rescue false)
    return Integer(param) if type == Integer
    return Float(param) if type == Float
    return String(param) if type == String
    return Date.parse(param) if type == Date
    return Time.parse(param) if type == Time
    return DateTime.parse(param) if type == DateTime
    return nil
  rescue ArgumentError
     puts "'#{param}' is not a valid #{type}"
  end
end

def check_required_parameters(params, possible_params)
  # Check all the parameters
  required_params_exist = required_params.map { |x| params.include?(x) ? true : x}
  unless required_params_exist.all? { |param| param == true }
    puts "Missing #{required_params_exist} parameter(s)"
    return false
  end
  return true
end

def check_parameter_types(params, possible_params)
  correct_param_values = params.map {|key, value| coerce(value, possible_params[key][:type]) ? true : key}
  unless correct_param_values.all? { |param| param == true }
    puts "Parameter#{correct_param_values.delete_if{ |x| x==true }} is not the right type"
    return false
  end
  return true
end

def check_parameter_values(params, possible_params)
  # Check all the min/max
  min_values = possible_params.map { |key, value| value[:min] ? key : nil }.compact
  max_values = possible_params.map { |key, value| value[:max] ? key : nil }.compact

  min_values_satisfied = min_values.map { |key| params[key] > possible_params[key][:min]}.all?
  max_values_satisfied = max_values.map { |key| params[key] > possible_params[key][:max]}.all?
  unless (max_values_satisfied and min_values_satisfied)
    puts "Not all maximum values satisfied"
    return false
  end
  return true
end

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

  required_params = check_required_parameters(params, possible_params)
  correct_param_types = check_parameter_types(params, possible_params)
  correct_param_values = check_parameter_values(params, possible_params)

  puts required_params
  puts correct_param_types
  puts correct_param_values
  # if (required_params and correct_param_types and correct_param_values)
  #   if params.key?("over")
  #    result = CricketScoreConsumer.get_score_at_over_ball(params["match_id"], params["innings"], params["over"], params["ball"]) 
  #   else
  #    result = CricketScoreConsumer.get_score_at_datetime(params["match_id"], params["datetime"]) 
  #   end
  # end

  return "result"
end

