require 'rubygems'
require 'bundler/setup'
require 'yaml'
require 'date'
require 'json'
require 'json-schema'
require 'logger'
require 'listen'
require_relative './helpers/cricket_entity_store.rb'
require_relative './helpers/cricket_event_store.rb'

# TODO:
# - Change props to be ENV?
#  - When failing to find a match you need to break

settings = {
    :game_path => ENV["GAME_PATH"].nil? ? "/games/" : ENV["GAME_PATH"]
} 
# Lookup to match the event types to the spec
$event_type_lookup = {
 "bowled" => "bowled",
 "caught" => "caught",
 "caught and bowled" => "caughtAndBowled", 
 "lbw" => "lbw",
 "stumped" => "stumped",
 "run out" => "runOut",
 "retired hurt" => "retiredHurt",
 "hit wicket" => "hitWicket",
 "obstructing the field" => "obstruction",
 "hit the ball twice" => "doubleHit",
 "handled the ball" => "handledBall",
 "timed out" => "timedOut",
 "legbyes" => "legBye",
 "noballs" => "noBall",
 "penalty" => "penaltyRuns",
 "wides" => "wide",
 "byes" => "bye"
}

def match_to_json(match)
  output =
     {
          "match" => match["match"]["match"],
          "eventType" => "#{match["type"]["eventType"]}",
          "timestamp"=> "#{match["timestamp"]["timestamp"]}",
          "ball" => {
              "battingTeam" => {
                  "id"=> match["batting_team"]["id"],
                  "name"=> "#{match["batting_team"]["name"]}"
              },
              "fieldingTeam"=> {
                  "id"=> match["fielding_team"]["id"],
                  "name"=> "#{match["fielding_team"]["name"]}"
              },
              "innings"=> match["innings"]["innings"],
              "over"=> match["over"]["over"].to_i,
              "ball"=> match["ball"]["ball"].to_i
          },
          "runs"=> match["runs"]["runs"],
          "batsmen"=> {
              "striker"=> {
                "id"=> match["striker"]["id"],
                "name"=> "#{match["striker"]["name"]}"
              },
              "nonStriker"=> {
                "id"=> match["non_striker"]["id"],
                "name"=> "#{match["non_striker"]["name"]}"
              }
          },
          "bowler"=> {
                "id"=> match["bowler"]["id"],
                "name"=> "#{match["bowler"]["name"]}"
          }
      }

    if (match["type"]["eventType"] == "run out" or match["type"]["eventType"] == "stumped" or match["type"]["eventType"] == "caught")

      output["fielder"] = {
             "id" => match["fielder"]["id"],
             "name"=> "#{match["fielder"]["name"]}"
           }
    end
    return output
end

module CricketEntityParser

  def self.parse_team(team)
    found_team = CricketEntityStore.get_team(team)
    # If we didn't have this team stored, create it and then push to ES
    if found_team.nil? || found_team.empty?
      new_team = CricketEntityStore.create_team(team)
      return {"id" => new_team["id"], "name" => new_team["name"]}
    else
      return {"id" => found_team.first["id"], "name" => found_team.first["name"]}
    end
  end

  def self.parse_innings(innings)
    return {"team" => innings.first["team"], "deliveries" => innings.first["deliveries"]}
  end

  def self.parse_player(player)
    found_player = CricketEntityStore.get_player(player)
    if found_player.nil? || found_player.empty?
      new_player = CricketEntityStore.create_player(player)
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
    over = {"over" => overball[0].to_i}
    ball = {"ball" => overball[1].to_i}

  end

  def self.parse_event_type(event_type)
    if event_type.key?("wicket")
      return {"eventType" => $event_type_lookup[event_type["wicket"]["kind"]]}
    elsif event_type.key?("extras")
      return {"eventType" =>  $event_type_lookup[event_type["extras"].keys.first]}
    else
      return {"eventType" => "delivery"}
    end
  end

  def self.parse_runs(deliveries)
    # Runs should be the physical runs taken, therefore it should be the score attributed to the batsman. Unless it's byes/legbyes which are counted as extras
     if (deliveries.has_key?("extras") and \
          ((deliveries["extras"].keys.first == "legbyes") or (deliveries["extras"].keys.first == "byes")))
       return {"runs" => deliveries["runs"]["extras"]}
     else
      return {"runs" => deliveries["runs"]["batsman"]}
    end
  end

  def self.parse_match(match_metadata)
    found_match = CricketEntityStore.get_match(
    match_metadata["teams"][0],
    match_metadata["teams"][1],
    match_metadata["match_type"].downcase == "test" ? 2 : 1,
    match_metadata["overs"],
    match_metadata["dates"].first)
    if found_match.nil? || found_match.empty?
      # Create a match ID
      new_match = CricketEntityStore.create_match(
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

# Set up logging
$logger = Logger.new(STDOUT)
$logger.error(ENV)

# Get the JSON schema
begin
  schema = JSON.parse(File.read('event_schema.json'))
rescue IOError => e
  $logger.fatal("Unable to open or parse JSON schema #{e}")
  exit
end

def process_game(game)
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
    # If we already have this match then break out
    if match == nil?
      return
    end

    yaml_innings = game["innings"]

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
          timestamp = {"timestamp" => game_metadata["dates"].first}

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

          # Do the JSON validation
          begin
            JSON::Validator.validate!(schema, event)
          rescue JSON::Schema::ValidationError => e
            $logger.fatal("Incorrect JSON created for event #{e}")
            e.message
            exit
          end
          puts event
          #CricketEventStore.append_to_stream(event)
          $logger.info("Pushing event to stream")
        end
      end
    end
    $logger.info("Finished pushing match to EventStore")
end

# Start listening for file changes
# TODO: Tryi f the directory doesn't exist
listener = Listen.to(Dir.pwd + settings[:game_path], only: /\.yaml/, force_polling: true) do |modified, added|
  unless added.nil? or added.empty?
   $logger.info("Found YAML file(s) for processing")
    begin
      added.each do |x|
         $logger.info("Processing file #{x}")  
         game = YAML.load_file(x.to_s)
         process_game(game)
         done_file = File.open(Dir.pwd + setings[:game_path] + x.to_s)
         done_file.rename(x.to_s, x.to_s + ".done" )
        puts done_file 
      end
    rescue Errno::ENOENT => e
      $logger.fatal("Unable to open game file at #{added.first} #{e}")
      exit
    end
  end
end
listener.start # not blocking
sleep



