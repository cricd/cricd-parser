require 'rubygems'
require 'bundler/setup'

require 'httparty'
require 'yaml'
require 'securerandom'
require 'date'
require 'json'
require 'http_eventstore'
require 'pp'
require_relative 'properties.rb'
require_relative 'cricket_entity_source.rb'

# TODO:
# - Change the event types to be the same as the spec
# - Fix the issue where legbyes are 0 runs


def snake_to_camel(string)
  str_array = string.split("_")
  first_element = str_array.shift
  capitalized_string = str_array.map{ |x| x.capitalize!}.join
  return first_element + capitalized_string
end

def match_to_json(match)
    output =
     {
          "match" => "#{match["match"]["match"]}",
          "eventType" => "#{match["type"]["eventType"]}",
          "timestamp"=> "#{match["timestamp"]["timestamp"]}",
          "ball" => {
              "battingTeam" => {
                  "id"=> "#{match["batting_team"]["id"]}",
                  "name"=> "#{match["batting_team"]["name"]}"
              },
              "fieldingTeam"=> {
                  "id"=> "#{match["fielding_team"]["id"]}",
                  "name"=> "#{match["fielding_team"]["name"]}"
              },
              "innings"=> "#{match["innings"]["innings"]}",
              "over"=> "#{match["over"]["over"]}",
              "ball"=> "#{match["ball"]["ball"]}"
          },
          "runs"=> "#{match["runs"]["runs"]}",
          "batsmen"=> {
              "striker"=> {
                "id"=> "#{match["striker"]["id"]}",
                "name"=> "#{match["striker"]["name"]}"
              },
              "nonStriker"=> {
                "id"=> "#{match["non_striker"]["id"]}",
                "name"=> "#{match["non_striker"]["name"]}"
              }
          },
          "bowler"=> {
                "id"=> "#{match["bowler"]["id"]}",
                "name"=> "#{match["bowler"]["name"]}"
          }
      }

    if (match["type"]["eventType"] == "run out" or match["type"]["eventType"] == "stumped" or match["type"]["eventType"] == "caught")

      output["fielder"] = {
             "id" => "#{match["fielder"]["id"]}",
             "name"=> "#{match["fielder"]["name"]}"
           }
    end
    return output
end


module CricketEntityParser

  def self.parse_team(team)
    found_team = CricketEntitySource.get_team(team)
    # If we didn't have this team stored, create it and then push to ES
    if found_team.nil? || found_team.empty?
      new_team = CricketEntitySource.create_team(team)
      return {"id" => new_team["id"], "name" => new_team["name"]}
    else
      return {"id" => found_team.first["id"], "name" => found_team.first["name"]}
    end
  end

  def self.parse_innings(innings)
    return {"team" => innings.first["team"], "deliveries" => innings.first["deliveries"]}
  end

  def self.parse_player(player)
    found_player = CricketEntitySource.get_player(player)
    if found_player.nil? || found_player.empty?
      new_player = CricketEntitySource.create_player(player)
      return {"id" => new_player["id"], "name" => new_player["name"]}
    else
      return {"id" => found_player.first["id"], "name" => found_player.first["name"]}
    end
  end

  def self.parse_players(deliveries)
    striker = self.parse_player(deliveries["batsman"])
    non_striker = self.parse_player(deliveries["non_striker"])
    bowler = self.parse_player(deliveries["bowler"])
    if deliveries.key?("wicket") and deliveries["wicket"].key?("fielders")
      fielder = CricketEntityParser.parse_player(deliveries["wicket"]["fielders"].first)
    end

    return striker, non_striker, bowler, fielder
  end

  def self.parse_deliveries(deliveries)

    # Get the over and ball
    overball = delivery.keys.first.to_s.split(".")
    over = {"over" => overball[0]}
    ball = {"ball" => overball[1]}

  end

  def self.parse_event_type(event_type)
    if event_type.key?("wicket")
      return {"eventType" => snake_to_camel(event_type["wicket"]["kind"])}
    elsif event_type.key?("extras")
      return {"eventType" =>  snake_to_camel(event_type["extras"].keys.first)}
    else
      return {"eventType" => "delivery"}
    end
  end

  def self.parse_runs(deliveries)
    # Runs should be the physical runs taken, therefore it should be the score attributed to the batsman. Unless it's byes/legbyes which are counted as extras
    if deliveries.has_key?("extras") && (deliveries["extras"].keys.first == "legbyes" || deliveries["extras"].keys.first == "byes")
      return {"runs" => deliveries["runs"]["extras"]}
    else
      return {"nuns" => deliveries["runs"]["batsman"]}
    end
  end

  def self.parse_match(match_metadata)
    found_match = CricketEntitySource.get_match(
    match_metadata["teams"][0],
    match_metadata["teams"][1],
    match_metadata["match_type"].downcase == "test" ? 2 : 1,
    match_metadata["overs"],
    match_metadata["dates"].first)
    if found_match.nil? || found_match.empty?
      # Create a match ID
      new_match = CricketEntitySource.create_match(
        match_metadata["teams"][0],
        match_metadata["teams"][1],
        match_metadata["match_type"].downcase == "test" ? 2 : 1,
        match_metadata["overs"],
        match_metadata["dates"].first
      )
      return match = {"match" => new_match["id"]}
    else
      return match = {"match" => found_match["id"]}
    end
  end
end

# Set up EventStore
es_props = Properties.get("eventstore")
client = HttpEventstore::Connection.new do |config|
  config.endpoint = es_props["ip"]
  config.port = es_props["port"]
  config.page_size = '20'
end


# Parse out all the deliveries to an array
game = YAML.load_file(Properties.get("game_path"))

# Grab me some meta-data
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
game_metadata["teams"].map! { |team| CricketEntityParser.parse_team(team) } 
teams = game_metadata["teams"]

# Parse out the innings
innings = game["innings"].first.map { |innings| CricketEntityParser.parse_innings(innings) }
match = CricketEntityParser.parse_match(game_metadata)

yaml_innings = game["innings"]
# [{"1st innings" =>
# {team => ...,
# "deliveries =>
# [{0.1 => }]}
# },
# {"2nd innings"=>
# {"team"=>"United Arab Emirates",
#  "deliveries"=>
#  [{0.1=>}]
# }]

#  Create an array with all the optional fields
yaml_innings.each_with_index do |innings, index|
  innings.each do |innings_key, innings_info|
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
    innings = {"innings" => index+1}

    # For all of the deliveries
    # innings_info["deliveries"] is an array of deliveries
    # e.g.
    # {0.1=>
    #    {"batsman"=>"MR Swart",
    #     "bowler"=>"Qadeer Ahmed",
    #     "non_striker"=>"SJ Myburgh",
    #     "runs"=>{"batsman"=>0, "extras"=>0, "total"=>0}}}
    innings_info["deliveries"].each do |delivery|

      delivery_values = delivery.values.first

      # Get the over and ball
      overball = delivery.keys.first.to_s.split(".")
      over = {"over" => overball[0]}
      ball = {"ball" => overball[1]}

      striker, non_striker, bowler, fielder = CricketEntityParser.parse_players(delivery_values)
      event_type = CricketEntityParser.parse_event_type(delivery_values)
      runs = CricketEntityParser.parse_runs(delivery_values)

        # Set the number of runs scored by the batsman, and fake the timestamp
        timestamp = {"timestamp" => DateTime.now.iso8601}

        # Create a new event with the data parsed
        values = {
          "match" => match,
          "type" => event_type,
          "timestamp" => timestamp,
          "batting_team" => batting_team,
          "fielding_team" => fielding_team,
          "innings" => innings,
          "over" => over,
          "ball" => ball,
          "runs" => runs,
          "striker" => striker,
          "non_striker" => non_striker,
          "bowler" => bowler,
          "fielder" => fielder}

        # Create the string of the event and push to ES
        event = match_to_json(values)

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
        end
    end
  end
end


