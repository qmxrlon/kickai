class FetchMatchesJob < ApplicationJob
  queue_as :default

  def perform
    client = FootballDataClient.new

    League.active.each do |league|
      next unless league.external_id.present?

      begin
        matches = client.fetch_matches(league.external_id)
        upsert_matches(matches, league)
        Rails.logger.info "[FetchMatchesJob] Synced #{matches.size} matches for #{league.name}"
      rescue FootballDataClient::RateLimitError => e
        Rails.logger.warn "[FetchMatchesJob] Rate limited for #{league.name}: #{e.message}"
        sleep 60
        retry
      rescue StandardError => e
        Rails.logger.error "[FetchMatchesJob] Error for #{league.name}: #{e.message}"
      end
    end
  end

  private

  def upsert_matches(raw_matches, league)
    raw_matches.each do |raw|
      home_team = Team.find_or_create_by(external_id: raw[:home_team_id], league: league) do |t|
        t.name = raw[:home_team_name]
      end
      away_team = Team.find_or_create_by(external_id: raw[:away_team_id], league: league) do |t|
        t.name = raw[:away_team_name]
      end

      match = Match.find_or_initialize_by(external_id: raw[:external_id])
      match.assign_attributes(
        league:       league,
        home_team:    home_team,
        away_team:    away_team,
        scheduled_at: raw[:utc_date],
        status:       map_status(raw[:status]),
        home_score:   raw.dig(:score, :fullTime, :home),
        away_score:   raw.dig(:score, :fullTime, :away)
      )
      match.save! if match.changed?
    end
  end

  def map_status(api_status)
    case api_status.to_s.upcase
    when "TIMED", "SCHEDULED" then :scheduled
    when "IN_PLAY", "PAUSED"  then :in_progress
    when "FINISHED"           then :finished
    when "POSTPONED"          then :postponed
    when "CANCELLED", "ABANDONED" then :cancelled
    else :scheduled
    end
  end
end
