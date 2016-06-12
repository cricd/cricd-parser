class CricketScore
  attr_accessor :runs, :over, :ball, :wickets

  def initialize(runs, over, ball, wickets)
    @runs = runs
    @over = over
    @ball = ball
    @wickets = wickets
  end

  def update_from_event(event)
    # Assuming all extras are 1 run
    if event.is_extra?()
      @runs += 1
    end
    @runs += event.instance_variable_get(:@runs).to_i
    @over = event.instance_variable_get(:@over).to_i
    @ball = event.instance_variable_get(:@ball).to_i
    if event.is_wicket?()
      @wickets += 1
    end
  end

  def to_s
    return "#{@runs}/#{@wickets} off #{@over}.#{@ball}"
  end

end
