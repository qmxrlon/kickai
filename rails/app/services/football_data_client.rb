# Client for the Football-Data.org API (https://www.football-data.org)
class FootballDataClient
  class RateLimitError < StandardError; end
  class ApiError       < StandardError; end

  BASE_URL = "https://api.football-data.org/v4/"
  API_KEY  = ENV.fetch("FOOTBALL_DATA_API_KEY", "")

  def initialize
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request  :retry, max: 3, interval: 2, retry_statuses: [429, 500]
      f.response :json
      f.options.timeout      = 20
      f.options.open_timeout = 5
    end
  end

  # Returns array of match hashes for a competition
  def fetch_matches(competition_id, date_from: nil, date_to: nil)
    params = { status: "SCHEDULED,IN_PLAY,FINISHED" }
    params[:dateFrom] = date_from.strftime("%Y-%m-%d") if date_from
    params[:dateTo]   = date_to.strftime("%Y-%m-%d")   if date_to

    resp = get("competitions/#{competition_id}/matches", params)
    (resp["matches"] || []).map { |m| normalize_match(m) }
  end

  def fetch_standings(competition_id)
    resp = get("competitions/#{competition_id}/standings")
    resp["standings"]
  end

  def fetch_team_matches(team_id, limit: 15)
    resp = get("teams/#{team_id}/matches", { status: "FINISHED", limit: limit })
    (resp["matches"] || []).map { |m| normalize_match(m) }
  end

  private

  def get(path, params = {})
    response = @conn.get(path) do |req|
      req.headers["X-Auth-Token"] = API_KEY
      req.params.merge!(params)
    end

    case response.status
    when 200      then response.body
    when 429      then raise RateLimitError, "Rate limited by Football-Data.org"
    when 400..499 then raise ApiError, "Client error #{response.status}: #{response.body['message']}"
    else               raise ApiError, "Server error #{response.status}"
    end
  end

  def normalize_match(m)
    {
      external_id:      m["id"].to_s,
      utc_date:         Time.parse(m["utcDate"]),
      status:           m["status"],
      home_team_id:     m.dig("homeTeam", "id")&.to_s,
      home_team_name:   m.dig("homeTeam", "name"),
      away_team_id:     m.dig("awayTeam", "id")&.to_s,
      away_team_name:   m.dig("awayTeam", "name"),
      home_score:       m.dig("score", "fullTime", "home"),
      away_score:       m.dig("score", "fullTime", "away")
    }
  end
end
