require_relative 'properties.rb'

module CricketEntitySource
  config = Properties.get("cricket_entity_source")
  @url = "http://#{config[:ip]}:#{config[:port]}"

  def self.create_team(name)
    response = HTTParty.post("#{@url}/teams",
                  :body => {"name" => "#{name}"}.to_json,
                  :headers => { 'Content-Type' => 'application/json'},
                  :timeout => 1
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

  def self.get_team(name)
    response = HTTParty.get("#{@url}/teams",
                             :query => {'name' => name},
                             :headers => { 'Content-Type' => 'application/json'},
                             :timeout => 1
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

  def self.get_match(home_team, away_team, number_of_innings, limited_overs, start_date)
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

  def self.create_match(home_team, away_team, number_of_innings, limited_overs, start_date)
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

  def self.create_player(name)
    response = HTTParty.post("#{@url}/players",
                           :body => {"name" => "#{name}"}.to_json,
                           :headers => { 'Content-Type' => 'application/json'},
                           :timeout => 1
                          )
  case response.code
  when 200...299
    return JSON.parse(response.body)
  when 400...500
    puts "Failed to create player with a #{response.code} code - #{response.body}"
    return nil
  when 500...600
    puts "Failed to create a player with a #{response.code} code"
    return nil
  else
    puts "Unknown response #{response.code} code"
    return nil
  end
  end

  def self.get_player(name)
    response = HTTParty.get("#{@url}/players",
                            :query => {'name' => name},
                            :headers => { 'Content-Type' => 'application/json'},
                            :timeout => 1
                           )
    case response.code
    when 200...299
      return JSON.parse(response.body)
    when 400...500
      puts "Failed to get player with a #{response.code} code - #{response.body}"
      return nil
    when 500...600
      puts "Failed to get player with a #{response.code} code"
      return nil
    else
      puts "Unknown response #{response.code} code"
      return nil
    end
  end
end
