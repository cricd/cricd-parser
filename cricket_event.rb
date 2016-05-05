
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
