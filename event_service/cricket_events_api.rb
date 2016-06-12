require 'date'
require 'sinatra/base'
require 'sinatra/param'
require 'json'
require 'http_eventstore'
require 'time'
require 'logger'


$logger = Logger.new(STDOUT)

# Pull the settings from ENV variables
settings = {
  :ip => ENV["EVENTSTORE_IP"].nil? ? "localhost" : ENV["EVENTSTORE_IP"],
  :port => ENV["EVENTSTORE_PORT"].nil? ? "2113" : ENV["EVENTSTORE_PORT"],
  :stream_name => ENV["EVENTSTORE_STREAM_NAME"].nil? ? "cricket_events_v1" : ENV["EVENTSTORE_STREAM_NAME"]
}


# Set up ES
  $client = HttpEventstore::Connection.new do |config|
    config.endpoint = settings[:ip]
    config.port = settings[:port]
    config.page_size = '50'
  end
    $stream_name = settings[:stream_name]

# Store all known events and id
begin
$all_events = $client.read_all_events_forward($stream_name)
$last_read_id = $all_events.last.id
rescue Faraday::ConnectionFailed => e
  $logger.fatal("Connection to EventStore failed -  #{e}")
  exit
rescue HttpEventstore::StreamNotFound => e
  $logger.fatal("Unable to find stream #{$stream_name} - #{e}")
end


class App < Sinatra::Base
  helpers Sinatra::Param

  configure do
    set :bind, '0.0.0.0'
  end

  before do
    content_type :json
  end

  get '/match' do

  param :id,          String, required: true
  param :bowler,      String
  param :batsman,     String
  one_of :bowler, :batsman

    new_events = $client.read_events_forward($stream_name, $last_read_id, 1000)
    if new_events != nil
      $last_read_id = new_events.last.id
      $all_events = $all_events + new_events
    end
    events_to_parse = $all_events

    if !params[:bowler].nil?
    events_to_parse.keep_if do |event|
      event["data"]["match"] == params[:id] \
      and event["data"]["bowler"]["id"] == params[:bowler]
    end
  elsif !params[:batsman].nil?
    events_to_parse.keep_if do |event|
      event["data"]["match"] == params[:id] \
      and (event["data"]["batsmen"]["striker"]["id"] == params[:batsman] \
      or (event["data"]["batsman"] and event["data"]["batsman"]["id"] == params[:batsman]))
    end
  else
    events_to_parse.keep_if do |event|
      event["data"]["match"] == params[:id]
    end
  end

  return events_to_parse.to_json()
end

  get '/bowler' do
  param :id,          String, required: true


  begin
    new_events = $client.read_events_forward($stream_name, $last_read_id, 1000)
    $last_read_id = new_events.last.id
    $all_events = $all_events + new_events
    events_to_parse = $all_events
  rescue HttpEventstore::StreamNotFound => e
    events_to_parse = nil
  end


  events_to_parse.keep_if do |event|
    !event["data"]["bowler"].nil? and event["data"]["bowler"]["id"] == params[:id]
  end
  return events_to_parse.to_json()
end

  get '/batsman' do
  batsman_id = params["id"]
  param :id,          String, required: true

  begin
    new_events = $client.read_events_forward($stream_name, $last_read_id, 1000)
    $last_read_id = new_events.last.id
    $all_events = $all_events + new_events
    events_to_parse = $all_events
  rescue HttpEventstore::StreamNotFound => e
    events_to_parse = nil
  end
  
  events_to_parse.keep_if do |event|
    ((!event["data"]["batsman"].nil? and event["data"]["batsman"]["id"] == params[:id]) \
    or \
    event["data"]["batsmen"]["striker"]["id"] == params[:id])
  end

  return events_to_parse.to_json()
  end

end
App.run!
