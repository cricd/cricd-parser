require 'rubygems'
require 'bundler/setup'

require 'httparty'
require 'yaml'
require 'SecureRandom'
require 'Date'
require 'json'
require 'http_eventstore'
require 'pp'
require_relative 'properties.rb'


# TODO:
# - Change the event types to be the same as the spec


def snake_to_camel(string)
  str_array = string.split("_")
  first_element = str_array.shift
  capitalized_string = str_array.map{ |x| x.capitalize!}.join
  return first_element + capitalized_string
end


class CricketEntitySource
  def initialize(ip, port)
    @ip = ip
    @port = port
    @url = "http://#{@ip}:#{port}"
  end

  def create_team(name)
    response = HTTParty.post("#{@url}/teams",
                  :body => {"name" => "#{name}"}.to_json,
                  :headers => { 'Content-Type' => 'application/json'}
                 )
    case response.code
    when 200...299
      return JSON.parse(response.body)
    when 400...500
      puts "Failed to create team with a #{response.code} code - #{response.body}"
      return nil
    when 500...600
      puts "Failed to create a team with a #{response.code} code"
      return nil
    else
      puts "Unknown response #{response.code} code"
      return nil
    end
  end

  def get_team(name)
    response = HTTParty.get("#{@url}/teams",
                             :query => {'name' => name},
                             :headers => { 'Content-Type' => 'application/json'}
                            )
    case response.code
    when 200...299
      return JSON.parse(response.body)
    when 400...500
      puts "Failed to get team with a #{response.code} code - #{response.body}"
      return nil
    when 500...600
      puts "Failed to get team with a #{response.code} code"
      return nil
    else
      puts "Unknown response #{response.code} code"
      return nil
    end
  end

  def get_match(home_team, away_team, number_of_innings, limited_overs, start_date)
      response = HTTParty.get("#{@url}/matches",
                              :query => {'homeTeam' => home_team,
                                         'awayTeam' => away_team,
                                         'numberOfInnings' => number_of_innings,
                                         'limitedOvers' => limited_overs,
                                         'startDate' => start_date},
                              :headers => { 'Content-Type' => 'application/json'}
                             )
      case response.code
      when 200...299
        return JSON.parse(response.body)
      when 400...500
        puts "Failed to get match with a #{response.code} code - #{response}"
        return nil
      when 500...600
        puts "Failed to get match with a #{response.code} code"
        return nil
      else
        puts "Unknown response #{response.code} code"
        return nil
      end
    end

  def create_match(home_team, away_team, number_of_innings, limited_overs, start_date)
    response = HTTParty.post("#{@url}/matches",
                               :body => {'homeTeam' => home_team,
                                          'awayTeam' => away_team,
                                          'numberOfInnings' => number_of_innings,
                                          'limitedOvers' => limited_overs,
                                          'startDate' => start_date}.to_json,
                               :headers => { 'Content-Type' => 'application/json'}
                              )
    case response.code
    when 200...299
        return JSON.parse(response.body)
      when 400...500
        puts "Failed to get match with a #{response.code} code"
        return nil
      when 500...600
        puts "Failed to get match with a #{response.code} code"
        return nil
      else
        puts "Unknown response #{response.code} code"
        return nil
      end
    end

  def create_player(name)
  response = HTTParty.post("#{@url}/players",
                           :body => {"name" => "#{name}"}.to_json,
                           :headers => { 'Content-Type' => 'application/json'}
                          )
  case response.code
  when 200...299
    return JSON.parse(response.body)
  when 400...500
    puts "Failed to create team with a #{response.code} code - #{response.body}"
    return nil
  when 500...600
    puts "Failed to create a team with a #{response.code} code"
    return nil
  else
    puts "Unknown response #{response.code} code"
    return nil
  end
  end

  def get_player(name)
    response = HTTParty.get("#{@url}/players",
                            :query => {'name' => name},
                            :headers => { 'Content-Type' => 'application/json'}
                           )
    case response.code
    when 200...299
      return JSON.parse(response.body)
    when 400...500
      puts "Failed to get team with a #{response.code} code - #{response.body}"
      return nil
    when 500...600
      puts "Failed to get team with a #{response.code} code"
      return nil
    else
      puts "Unknown response #{response.code} code"
      return nil
    end
  end
end




class CricketEvent
  def initialize(match, type, timestamp, batting_team, fielding_team, innings, over, ball, runs, striker, non_striker, bowler, fielder)
    @match = match
    @type = type
    @timestamp = timestamp
    @batting_team = batting_team
    @fielding_team = fielding_team
    @innings = innings
    @over = over
    @ball = ball
    @runs = runs
    @striker = striker
    @non_striker = non_striker
    @bowler = bowler
    @fielder = fielder
  end

  def to_string()
     output = 
      {
          "match" => "#{@match["match"]}",
          "eventType" => "#{@type["eventType"]}",
          "timestamp"=> "#{@timestamp["timestamp"]}",
          "ball" => {
              "battingTeam" => {
                  "id"=> "#{@batting_team["id"]}",
                  "name"=> "#{@batting_team["name"]}"
              },
              "fieldingTeam"=> {
                  "id"=> "#{@fielding_team["id"]}",
                  "name"=> "#{@fielding_team["name"]}"
              },
              "innings"=> "#{@innings["innings"]}",
              "over"=> "#{@over["over"]}",
              "ball"=> "#{@ball["ball"]}"
          },
          "runs"=> "#{@runs["runs"]}",
          "batsmen"=> {
              "striker"=> {
                "id"=> "#{@striker["id"]}",
                "name"=> "#{@striker["name"]}"
              },
              "nonStriker"=> {
                "id"=> "#{@non_striker["id"]}",
                "name"=> "#{@non_striker["name"]}"
              }
          },
          "bowler"=> {
                "id"=> "#{@bowler["id"]}",
                "name"=> "#{@bowler["name"]}"
          }
      }

      if (@type["eventType"] == "run out" or @type["eventType"] == "stumped" or @type["eventType"] == "caught")
        output["fielder"] = {
             "id" => "#{@fielder["id"]}",
             "name"=> "#{@fielder["name"]}"
           }
      end

    return output
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

# Set up the CricketEntitySource
entity_source = CricketEntitySource.new(
  all_properties["cricket_entity_source"]["ip"],
  all_properties["cricket_entity_source"]["port"])

# Parse out all the deliveries to an array
game = YAML.load_file(all_properties["game_path"])
game_metadata = {
  "dates" => game["info"]["dates"],
  "city" => game["info"]["city"],
  "venue" => game["info"]["venue"],
  "match_type" => game["info"]["match_type"],
  "outcome" => game["info"]["outcome"],
  "overs" => game["info"]["overs"],
  "teams" => game["info"]["teams"]
}


# Parse out the meta-data
teams = []
game_metadata["teams"].each do |team|
  found_team = entity_source.get_team(team)
  # If we didn't have this team stored, create it and then push to ES
  if found_team.nil? || found_team.empty?
    new_team = entity_source.create_team(team)
    teams.push({"id" => new_team["id"], "name" => new_team["name"]})
  else
    teams.push({"id" => found_team.first["id"], "name" => found_team.first["name"]})
  end
end

# Parse out the innings
innings = []
input_innings = game["innings"]
input_innings.each do |x|
  keys,values = x.first
  innings.push({"team" => values["team"], "deliveries" => values["deliveries"]})
end

# Create a match ID
new_match = entity_source.create_match(
  teams[0],
  teams[1],
  input_innings.length,
  game_metadata["match_type"].downcase == "test" ? 0 : 1, # It's only unlimited overs if it's a test
  game_metadata["dates"].first
)

match = {
  "match" => new_match["id"] 
}



# Create an array with all the optional fields
successful_events = 0 # This is bad fixme, please
innings.each_with_index do |innings_info, index|
    batting_team, fielding_team = {}
    # Get  the team name and ID
    teams.each do |team|
      if team["name"] == innings_info["team"]
        batting_team = team
      else
        fielding_team = team
      end
    end
    # Get the innings
    innings = {"innings" => index}

    innings_info["deliveries"].each do |delivery|

      # Get the over and ball
      x = delivery.keys
      overball = x.first.to_s.split(".")
      over = {"over" => overball[0]}
      ball = {"ball" => overball[1]}
      delivery.values.each do |x|

        found_striker = entity_source.get_player(x["batsman"])
        if found_striker.nil? || found_striker.empty?
          new_striker = entity_source.create_player(x["batsman"])
          striker = {"id" => new_striker["id"], "name" => new_striker["name"]}
        else
          striker = {"id" => found_striker.first["id"], "name" => found_striker.first["name"]}
        end

        found_non_striker = entity_source.get_player(x["non_striker"])
        if found_non_striker.nil? || found_non_striker.empty?
          new_non_striker = entity_source.create_player(x["non_striker"])
          non_striker = {"id" => new_non_striker["id"], "name" => new_non_striker["name"]}
        else
          non_striker = {"id" => found_non_striker.first["id"], "name" => found_non_striker.first["name"]}
        end

        found_bowler = entity_source.get_player(x["bowler"])
        if found_bowler.nil? || found_bowler.empty?
          new_bowler = entity_source.create_player(x["bowler"])
          bowler = {"id" => new_bowler["id"], "name" => new_bowler["name"]}
        else
          bowler = {"id" => found_bowler.first["id"], "name" => found_bowler.first["name"]}
        end

        # Set the fielder to be nil
        fielder = nil
        event_type = ""
        # If it's a wicket change the event type

        if x.has_key?("wicket")
          event_type = {"eventType" => x["wicket"]["kind"]}
        # If it had fielders make sure to include them
        if x["wicket"].has_key?("fielders")
          found_fielder = entity_source.get_player(x["wicket"]["fielders"].first)
          if found_fielder.nil? || found_fielder.empty?
            new_fielder = entity_source.create_player(x["wicket"]["fielders"].first)
            fielder = {"id" => new_fielder["id"], "name" => new_fielder["name"]}
          else
            fielder = {"id" => found_fielder.first["id"], "name" => found_fielder.first["name"]}
          end
        end

        # If it's extras, make sure the delivery is the right type
        elsif x.has_key?("extras")
          event_type = {"eventType" =>  x["extras"].keys.first}
        # Otherwise it's a delivery
        else
          event_type = {"eventType" => "delivery"}
        end

        # Set the number of runs scored by the batsman, and fake the timestamp
        runs = {"runs" => x["runs"]["batsman"]}
        timestamp = {"timestamp" => DateTime.now.iso8601}

        # Create a new event with the data parsed
        event = CricketEvent.new(
          match,
          event_type,
          timestamp,
          batting_team,
          fielding_team,
          innings,
          over,
          ball,
          runs,
          striker,
          non_striker,
          bowler,
          fielder
        )

        # Create the string of the event and push to ES
        event = event.to_string()

        # Push to event store
        stream_name = all_properties["eventstore"]["stream_name"]
        event_data = { event_type: "cricket_event",
                       data: event,
                       event_id: SecureRandom.uuid
                     }
        begin
          client.append_to_stream(stream_name, event_data)
        rescue StandardError => e
          puts "Error #{e}"
        else
         successful_events += 1 
        end
        end
    end
end
puts "Pushed #{successful_events} events to the `#{all_properties["eventstore"]["stream_name"]}` stream at http://#{all_properties["eventstore"]["ip"]}:#{all_properties["eventstore"]["port"]}"
