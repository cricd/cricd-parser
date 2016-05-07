
class CricketEvent
  def initialize(event, options)
    if event.nil?
    @match  = options["match"]
    @type  = options["type"]
    @timestamp  = options["timestamp"]
    @batting_team  = options["batting_team"]
    @fielding_team  = options["fielding_team"]
    @innings  = options["innings"]
    @over  = options["over"]
    @ball  = options["ball"]
    @runs  = options["runs"]
    @striker  = options["striker"]
    @non_striker  = options["non_striker"]
    @bowler  = options["bowler"]
    @fielder  = options["fielder"]
    else
      @match = event.data["match"],
      @type = event.data["eventType"],
      @timestamp = event.data["timestamp"],
      @batting_team = event.data["ball"]["battingTeam"],
      @fielding_team = event.data["ball"]["fieldingTeam"],
      @innings = event.data["ball"]["innings"],
      @over = event.data["ball"]["over"],
      @ball = event.data["ball"]["ball"],
      @runs = event.data["runs"],
      @striker = event.data["batsmen"]["striker"],
      @non_striker = event.data["batsmen"]["nonStriker"],
      @bowler = event.data["bowler"],
      @fielder = event.data["fielder"]
    end

 end

  def to_s()
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

  def is_wicket?()
    if ["bowled", "caught","caughtAndBowled", "lbw", "stumped", "run out", "retiredHurt", "hitWicket", "obstructingTheField", "hitTheBallWwice", "handledTheBall", "timedOut"].include?(@type)
      return true
    else
      return false
    end
  end

end
