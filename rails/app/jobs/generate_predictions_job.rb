class GeneratePredictionsJob < ApplicationJob
  queue_as :default

  # Can be called with a specific match_id or without to batch-process upcoming matches
  def perform(match_id = nil)
    matches = if match_id
                Match.where(id: match_id)
              else
                Match.upcoming
                     .where("scheduled_at <= ?", 7.days.from_now)
                     .where.missing(:prediction)
                     .limit(50)
              end

    api = PredictionApiClient.new

    matches.each do |match|
      begin
        result = api.predict(match)

        Prediction.upsert(
          {
            match_id:         match.id,
            home_win_prob:    result[:home_win_prob],
            draw_prob:        result[:draw_prob],
            away_win_prob:    result[:away_win_prob],
            over_under_probs: result[:over_under_probs],
            btts_prob:        result[:btts_prob],
            xg_home:          result[:xg_home],
            xg_away:          result[:xg_away],
            predicted_goals:  result[:predicted_goals],
            confidence_score: result[:confidence_score],
            value_rating:     result[:value_rating],
            recommended_bet:  result[:recommended_bet],
            kelly_fraction:   result[:kelly_fraction],
            ai_analysis:      result[:ai_analysis],
            model_version:    result[:model_version],
            created_at:       Time.current,
            updated_at:       Time.current
          },
          unique_by: :match_id
        )

        Rails.logger.info "[GeneratePredictionsJob] Prediction created for match #{match.id} (#{match.title})"
      rescue PredictionApiClient::ServiceUnavailableError => e
        Rails.logger.error "[GeneratePredictionsJob] Python service unavailable: #{e.message}"
        break
      rescue StandardError => e
        Rails.logger.error "[GeneratePredictionsJob] Failed for match #{match.id}: #{e.message}"
      end
    end
  end
end
