class FetchStandingsJob < ApplicationJob
  queue_as :low

  def perform
    client = FootballDataClient.new
    League.active.each do |league|
      next unless league.external_id.present?
      begin
        standings = client.fetch_standings(league.external_id)
        league.update!(standings_cache: standings, standings_cached_at: Time.current) if standings
      rescue StandardError => e
        Rails.logger.error "[FetchStandingsJob] Failed for #{league.name}: #{e.message}"
      end
    end
  end
end
