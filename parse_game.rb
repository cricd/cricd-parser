require 'rubygems'
require 'bundler/setup'


require 'yaml'
require 'SecureRandom'
require 'Date'
require 'JSON'
require 'http_eventstore'
require 'pp'
require_relative 'properties.rb'




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
  config.endpoint = all_properties["eventstore"]["eventstore_ip"]
  config.port = all_properties["eventstore"]["eventstore_port"]
  config.page_size = '20'
end



# Parse out all the deliveries to an array
game = YAML.load_file(all_properties["game_path"])
# Parse out the meta-data
teams = []
game['info']['teams'].each do |team|
  teams.push({"id" => SecureRandom.uuid, "name" => team})
end

# Parse out the innings
innings = []
input_innings = game["innings"]
input_innings.each do |x|
  keys,values = x.first
  innings.push({"team" => values["team"], "deliveries" => values["deliveries"]})
end

# Create a match ID
match = {
  "match" => SecureRandom.uuid
}

# Create an array with all the optional fields
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
        # Get the batsmen
        striker = {
          "id" => SecureRandom.uuid,
          "name" => x["batsman"]
        }

        non_striker = {
          "id" => SecureRandom.uuid,
          "name" => x["non_striker"]
        }

        # Get the bowler
        bowler = {
          "id" => SecureRandom.uuid,
          "name" => x["batsman"]
        }

        # Set the fielder to be nil
        fielder = nil

        event_type = ""
        # If it's a wicket change the event type
        if x.has_key?("wicket")
          event_type = {"eventType" => x["wicket"]["kind"]}
        # If it had fielders make sure to include them
        if x["wicket"].has_key?("fielders")
          fielder = {"id" => SecureRandom.uuid, "name" => x["wicket"]["fielders"].first}
        end

        # If it's extras, make sure the delivery is the right type
        elsif x.has_key?("extras")
          event_type = {"eventType" =>  x["extras"].keys.first}
        # Otherwise it's a delivery
        else
          event_type = {"eventType" => "delivery"}
        end

        # Set the number of runs scored, and fake the timestamp
        runs = {"runs" => x["runs"]["total"]}
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
        client.append_to_stream(stream_name, event_data)
      end
    end
end
