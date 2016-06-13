
class CricketEvent
  attr_accessor :ball, :over, :runs, :innings, :timestamp
  def initialize(event)
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

  def is_extra?()
    if ["wides", "noballs", "penalty"].include?(@type)
      return true
    else
      return false
    end
  end

  def is_wicket?()
    if ["bowled", "caught","caughtAndBowled", "lbw", "stumped", "run out", "retiredHurt", "hitWicket", "obstructingTheField", "hitTheBallWwice", "handledTheBall", "timedOut"].include?(@type)
      return true
    else
      return false
    end
  end

end
