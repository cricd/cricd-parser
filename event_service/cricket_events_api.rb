require 'date'
require 'sinatra/base'
require 'sinatra/param'
require 'json'
require 'http_eventstore'

# Pull the settings from ENV variables
settings = {
  :ip => ENV["EVENTSTORE_IP"].nil? ? "localhost" : ENV["EVENTSTORE_IP"],
  :port => ENV["EVENTSTORE_PORT"].nil? ? "2113" : ENV["EVENTSTORE_PORT"],
  :stream_name => ENV["EVENTSTORE_STREAM_NAME"].nil? ? "cricket_events_v1" : ENV["EVENTSTORE_STREAM_NAME"]
}

$client = HttpEventstore::Connection.new do |config|
  config.endpoint = settings[:ip]
  config.port = settings[:port]
  config.page_size = '20'
end
$stream_name = settings[:stream_name]


class App < Sinatra::Base
  helpers Sinatra::Param
  set :bind, '::'
  before do
    content_type :json
  end

  get '/match' do

  param :id,          String, required: true
  param :bowler,      String
  param :batsman,     String
  one_of :bowler, :batsman

  all_events = $client.read_all_events_forward($stream_name)
  if !params[:bowler].nil?
    all_events.keep_if do |event|
      event["data"]["match"] == params[:id] \
      and event["data"]["bowler"]["id"] == params[:bowler]
    end
  elsif !params[:batsman].nil?
    all_events.keep_if do |event|
      event["data"]["match"] == params[:id] \
      and (event["data"]["batsmen"]["striker"]["id"] == params[:batsman] \
      or (event["data"]["batsman"] and event["data"]["batsman"]["id"] == params[:batsman]))
    end
  else
    all_events.keep_if do |event|
      event["data"]["match"] == params[:id]
    end
  end

  return all_events.to_json()
end

  get '/bowler' do
  param :id,          String, required: true

  all_events = $client.read_all_events_forward($stream_name)
  all_events.keep_if do |event|
    !event["data"]["bowler"].nil? and event["data"]["bowler"]["id"] == params[:id]
  end
  return all_events.to_json()
end

  get '/batsman' do
  batsman_id = params["id"]
  param :id,          String, required: true

  all_events = $client.read_all_events_forward($stream_name)
  all_events.keep_if do |event|
    ((!event["data"]["batsman"].nil? and event["data"]["batsman"]["id"] == params[:id]) \
    or \
    event["data"]["batsmen"]["striker"]["id"] == params[:id])
  end

  return all_events.to_json()
  end

end
App.run!
