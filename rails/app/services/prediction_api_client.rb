# Calls the Python FastAPI prediction service.
class PredictionApiClient
  class ServiceUnavailableError < StandardError; end
  class PredictionError < StandardError; end

  BASE_URL  = ENV.fetch("PYTHON_API_URL", "http://python:8000")
  API_KEY   = ENV.fetch("PYTHON_API_SECRET", "")
  TIMEOUT   = 30

  def initialize
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request  :retry, max: 2, interval: 1, retry_statuses: [429, 500, 502, 503]
      f.response :json
      f.options.timeout      = TIMEOUT
      f.options.open_timeout = 10
    end
  end

  def predict(match)
    payload = build_payload(match)

    response = @conn.post("/predictions/generate") do |req|
      req.headers["Content-Type"]  = "application/json"
      req.headers["X-Api-Key"]     = API_KEY
      req.body = payload.to_json
    end

    raise ServiceUnavailableError, "Python service returned #{response.status}" unless response.success?

    body = response.body
    raise PredictionError, body["detail"] if body["detail"].present?

    parse_response(body)
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
    raise ServiceUnavailableError, "Python service unreachable: #{e.message}"
  end

  private

  def build_payload(match)
    {
      match_id:        match.id,
      external_id:     match.external_id,
      home_team_id:    match.home_team.external_id,
      away_team_id:    match.away_team.external_id,
      home_team_name:  match.home_team.name,
      away_team_name:  match.away_team.name,
      league_id:       match.league.external_id,
      scheduled_at:    match.scheduled_at.iso8601
    }
  end

  def parse_response(body)
    {
      home_win_prob:    body["home_win_prob"]&.to_f,
      draw_prob:        body["draw_prob"]&.to_f,
      away_win_prob:    body["away_win_prob"]&.to_f,
      btts_prob:        body["btts_prob"]&.to_f,
      xg_home:          body["xg_home"]&.to_f,
      xg_away:          body["xg_away"]&.to_f,
      predicted_goals:  body["predicted_goals"]&.to_f,
      over_under_probs: body["over_under_probs"],
      confidence_score: body["confidence_score"]&.to_f,
      value_rating:     body["value_rating"]&.to_i,
      recommended_bet:  body["recommended_bet"],
      kelly_fraction:   body["kelly_fraction"]&.to_f,
      ai_analysis:      body["ai_analysis"],
      model_version:    body["model_version"]
    }
  end
end
