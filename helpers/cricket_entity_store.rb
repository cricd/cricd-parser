require 'httparty'
require 'logger'

module CricketEntityStore
  config = {
    :ip => ENV["ENTITYSTORE_IP"].nil? ? "localhost" : ENV["ENTITYSTORE_IP"],
    :port => ENV["ENTITYSTORE_PORT"].nil? ? "1337" : ENV["ENTITYSTORE_PORT"],
  }
  @logger = Logger.new(STDOUT)
  @logger.level = Logger::WARN
  @url = "http://#{config[:ip]}:#{config[:port]}"
  @logger.info("Connecting to entity store at #{config[:ip]}:#{config[:port]}")

  def self.create_team(name)
    @logger.info("Trying to create team with name #{name}")
    response = HTTParty.post("#{@url}/teams",
                  :body => {"name" => "#{name}"}.to_json,
                  :headers => { 'Content-Type' => 'application/json'},
                  :timeout => 1
                  )
    case response.code
    when 200...299
      @logger.info("Team created with name: #{name}")
      return JSON.parse(response.body)
    when 400...500
      @logger.error("Failed to create team with a #{response.code} code - #{response.body}")
      return nil
    when 500...600
      @logger.error("Failed to create team with a #{response.code} code - #{response.body}")
      return nil
    else
      @logger.error("Failed to create team with a #{response.code} code")
      return nil
    end
  end

  def self.get_team(name)
    @logger.info("Trying to get team with name #{name}")
    response = HTTParty.get("#{@url}/teams",
                             :query => {'name' => name},
                             :headers => { 'Content-Type' => 'application/json'},
                             :timeout => 1
                           )
    case response.code
    when 200...299
      @logger.info("Team found with name: #{name}")
      return JSON.parse(response.body)
    when 400...500
      @logger.error("Failed to get team with a #{response.code} code - #{response.body}")
      return nil
    when 500...600
      @logger.error("Failed to get team with a #{response.code} code")
      return nil
    else
      @logger.error("Unknown response #{response.code} code")
      return nil
    end
  end

  def self.get_match(home_team, away_team, number_of_innings, limited_overs, start_date)
    @logger.info("Trying to get match between #{home_team} and #{away_team} on #{start_date}")
    response = HTTParty.get("#{@url}/matches",
                              :query => {'homeTeam' => home_team,
                                         'awayTeam' => away_team,
                                         'numberOfInnings' => number_of_innings,
                                         'limitedOvers' => limited_overs,
                                         'startDate' => start_date},
                              :headers => { 'Content-Type' => 'application/json'},
                              :timeout => 1
                             )
    case response.code
    when 200...299
      @logger.info("Match found between #{home_team} and #{away_team} on #{start_date}")
      return JSON.parse(response.body)
    when 400...500
      @logger.error("Failed to get match with a #{response.code} code - #{response.body}")
      return nil
    when 500...600
      @logger.error("Failed to get match with a #{response.code} code")
      return nil
    else
      @logger.error("Unknown response #{response.code} code")
      return nil
    end
  end

  def self.create_match(home_team, away_team, number_of_innings, limited_overs, start_date)
    @logger.info("Trying to get create between #{home_team} and #{away_team} on #{start_date}")
    response = HTTParty.post("#{@url}/matches",
                               :body => {'homeTeam' => home_team,
                                          'awayTeam' => away_team,
                                          'numberOfInnings' => number_of_innings,
                                          'limitedOvers' => limited_overs,
                                          'startDate' => start_date}.to_json,
                               :headers => { 'Content-Type' => 'application/json'},
                               :timeout => 1
                              )
    case response.code
    when 200...299
      @logger.info("Match created between #{home_team} and #{away_team} on #{start_date}")
      return JSON.parse(response.body)
    when 400...500
      @logger.error("Failed to get match with a #{response.code} code - #{response.body}")
      return nil
    when 500...600
      @logger.error("Failed to get match with a #{response.code} code")
      return nil
    else
      @logger.error("Unknown response #{response.code} code")
      return nil
    end
  end

  def self.create_player(name)
    @logger.info("Trying to create player with name #{name}")
    response = HTTParty.post("#{@url}/players",
                           :body => {"name" => "#{name}"}.to_json,
                           :headers => { 'Content-Type' => 'application/json'},
                           :timeout => 1
                          )
    case response.code
    when 200...299
      @logger.info("Player created with name: #{name}")
      return JSON.parse(response.body)
    when 400...500
      @logger.error("Failed to create player with a #{response.code} code - #{response.body}")
      return nil
    when 500...600
      @logger.error("Failed to create player with a #{response.code} code - #{response.body}")
      return nil
    else
      @logger.error("Failed to create player with a #{response.code} code")
      return nil
    end
  end

  def self.get_player(name)
    @logger.info("Trying to get player with name #{name}")
    response = HTTParty.get("#{@url}/players",
                            :query => {'name' => name},
                            :headers => { 'Content-Type' => 'application/json'},
                            :timeout => 1
                           )
    case response.code
    when 200...299
      @logger.info("Player found with name: #{name}")
      return JSON.parse(response.body)
    when 400...500
      @logger.error("Failed to get player with a #{response.code} code - #{response.body}")
      return nil
    when 500...600
      @logger.error("Failed to get player with a #{response.code} code - #{response.body}")
      return nil
    else
      @logger.error("Failed to get player with a #{response.code} code")
      return nil
    end
  end
end
