# db/seeds/dev_data.rb — Real teams, upcoming matches, and demo predictions.
# Run automatically in development via db/seeds.rb

puts "  Seeding dev match data..."

football = Sport.find_by!(slug: "football")

# ── Teams per league ─────────────────────────────────────────────────────────
teams_data = {
  "BL1" => [
    "Bayern München", "Borussia Dortmund", "Bayer Leverkusen", "RB Leipzig",
    "Eintracht Frankfurt", "VfB Stuttgart", "Borussia Mönchengladbach",
    "SC Freiburg", "Werder Bremen", "Wolfsburg", "Union Berlin",
    "Augsburg", "Mainz 05", "Hoffenheim", "Heidenheim"
  ],
  "BL2" => [
    "Hamburger SV", "Fortuna Düsseldorf", "Karlsruher SC", "Hannover 96",
    "1. FC Nürnberg", "FC St. Pauli", "Schalke 04", "VfL Osnabrück",
    "Greuther Fürth", "1. FC Magdeburg"
  ],
  "PL" => [
    "Manchester City", "Arsenal", "Liverpool", "Chelsea",
    "Manchester United", "Tottenham Hotspur", "Newcastle United",
    "Aston Villa", "Brighton & Hove Albion", "West Ham United",
    "Fulham", "Crystal Palace", "Everton", "Brentford", "Wolverhampton"
  ],
  "PD" => [
    "Real Madrid", "FC Barcelona", "Atlético Madrid", "Sevilla FC",
    "Real Sociedad", "Athletic Club", "Valencia CF", "Villarreal CF",
    "Real Betis", "Osasuna", "Getafe CF", "Celta Vigo", "Rayo Vallecano"
  ],
  "SA" => [
    "Juventus", "Inter Milan", "AC Milan", "Napoli", "AS Roma",
    "Lazio", "Atalanta", "Fiorentina", "Torino", "Bologna",
    "Udinese", "Hellas Verona", "Monza", "Lecce"
  ],
  "FL1" => [
    "Paris Saint-Germain", "Olympique Marseille", "Olympique Lyon",
    "AS Monaco", "LOSC Lille", "OGC Nice", "Stade Rennais",
    "RC Lens", "Nantes", "Montpellier HSC", "Strasbourg", "Toulouse FC"
  ],
  "DED" => [
    "Ajax", "PSV Eindhoven", "Feyenoord", "AZ Alkmaar",
    "FC Twente", "Utrecht", "NEC Nijmegen", "Vitesse"
  ],
  "PPL" => [
    "Benfica", "FC Porto", "Sporting CP", "SC Braga",
    "Vitória SC", "Casa Pia AC", "Gil Vicente", "Boavista"
  ],
  "CL" => [
    "Real Madrid", "Manchester City", "Bayern München", "PSG",
    "Arsenal", "Inter Milan", "Atlético Madrid", "Borussia Dortmund"
  ]
}

# Create teams (idempotent per league)
league_teams = {}
teams_data.each do |ext_id, names|
  league = League.find_by(external_id: ext_id)
  next unless league

  league_teams[ext_id] = names.map do |name|
    Team.find_or_create_by!(name: name, league: league)
  end
end
puts "    ✓ Teams (#{Team.count})"

# ── Helper to build a realistic prediction ───────────────────────────────────
def build_prediction(match, home_strength, away_strength)
  total = home_strength + away_strength + 1.0
  hw = (home_strength / total + rand * 0.08 - 0.04).clamp(0.10, 0.75).round(3)
  aw = (away_strength / total + rand * 0.08 - 0.04).clamp(0.10, 0.75).round(3)
  dw = (1.0 - hw - aw).clamp(0.08, 0.45).round(3)
  # Re-normalise
  sum = hw + dw + aw
  hw = (hw / sum).round(3); dw = (dw / sum).round(3); aw = (1.0 - hw - dw).round(3)

  xg_h = (home_strength * 0.8 + rand * 0.6).round(2)
  xg_a = (away_strength * 0.8 + rand * 0.6).round(2)
  pred_goals = (xg_h + xg_a).round(1)

  btts = ((xg_h > 0.9 && xg_a > 0.9) ? (0.45 + rand * 0.3) : (0.25 + rand * 0.2)).round(3)

  o15 = [hw + aw + 0.15, 0.95].min.round(3)
  o25 = [pred_goals > 2.2 ? 0.55 + rand * 0.25 : 0.30 + rand * 0.25, 0.92].min.round(3)
  o35 = [pred_goals > 3.0 ? 0.40 + rand * 0.2 : 0.20 + rand * 0.2, 0.75].min.round(3)

  confidence = (55 + rand * 30).to_i
  value_rating = case confidence
                 when 80.. then 5
                 when 70.. then 4
                 when 65.. then 3
                 when 58.. then 2
                 else 1
                 end

  outcome = if hw > aw && hw > dw then "home_win"
            elsif aw > hw && aw > dw then "away_win"
            else "draw"
            end

  kelly = ((hw - (1.0 - hw)) * 0.25).clamp(0, 0.15).round(4)

  analyses = [
    "#{match.home_team.name} zeigt starke Heimform mit #{(hw * 100).to_i}% Siegwahrscheinlichkeit. Das Pressing-Spiel sollte entscheidend sein.",
    "Beide Teams sind in guter Form. #{match.home_team.name} hat leichten Heimvorteil, aber #{match.away_team.name} kann die Partie offen halten.",
    "#{match.away_team.name} hat zuletzt auswärts überzeugt. Bei #{(o25 * 100).to_i}% Over 2.5 Wahrscheinlichkeit erwarten wir ein torreiches Spiel.",
    "Defensivstark, aber mit effizienten Kontern. KI-Modell favorisiert #{outcome == 'home_win' ? match.home_team.name : match.away_team.name} bei einem erwarteten xG von #{xg_h}-#{xg_a}.",
    "Schlüsselfaktor: Mittelfeldkontrolle. #{match.home_team.name} hat Heimvorteil, doch #{match.away_team.name} ist schwer zu schlagen."
  ]

  Prediction.find_or_create_by!(match: match) do |p|
    p.home_win_prob       = hw
    p.draw_prob           = dw
    p.away_win_prob       = aw
    p.btts_prob           = btts
    p.xg_home             = xg_h
    p.xg_away             = xg_a
    p.predicted_goals     = pred_goals
    p.over_under_probs    = { "1.5" => o15, "2.5" => o25, "3.5" => o35 }
    p.confidence_score    = confidence
    p.value_rating        = value_rating
    p.recommended_bet     = outcome
    p.kelly_fraction      = kelly
    p.ai_analysis         = analyses.sample
    p.model_version       = "xgb-v1.0-demo"
  end
end

# ── Upcoming matches (next 14 days) ──────────────────────────────────────────
upcoming_fixtures = [
  # Bundesliga
  { league: "BL1", home: "Bayern München",         away: "Borussia Dortmund",    days: 1,  hour: 18, hs: 2.2, as: 1.6 },
  { league: "BL1", home: "Bayer Leverkusen",        away: "RB Leipzig",           days: 1,  hour: 15, hs: 1.8, as: 1.7 },
  { league: "BL1", home: "Eintracht Frankfurt",     away: "VfB Stuttgart",        days: 2,  hour: 15, hs: 1.5, as: 1.4 },
  { league: "BL1", home: "Borussia Mönchengladbach",away: "Werder Bremen",        days: 7,  hour: 15, hs: 1.3, as: 1.1 },
  { league: "BL1", home: "SC Freiburg",             away: "Wolfsburg",            days: 7,  hour: 17, hs: 1.4, as: 1.2 },

  # Premier League
  { league: "PL",  home: "Arsenal",                 away: "Manchester City",      days: 2,  hour: 16, hs: 1.9, as: 2.1 },
  { league: "PL",  home: "Liverpool",               away: "Chelsea",              days: 3,  hour: 17, hs: 2.0, as: 1.5 },
  { league: "PL",  home: "Manchester United",       away: "Tottenham Hotspur",    days: 4,  hour: 15, hs: 1.4, as: 1.6 },
  { league: "PL",  home: "Newcastle United",        away: "Aston Villa",          days: 8,  hour: 15, hs: 1.6, as: 1.5 },

  # Primera División
  { league: "PD",  home: "Real Madrid",             away: "FC Barcelona",         days: 3,  hour: 21, hs: 2.3, as: 2.0 },
  { league: "PD",  home: "Atlético Madrid",         away: "Sevilla FC",           days: 5,  hour: 18, hs: 1.7, as: 1.2 },
  { league: "PD",  home: "Real Sociedad",           away: "Athletic Club",        days: 9,  hour: 20, hs: 1.5, as: 1.4 },

  # Serie A
  { league: "SA",  home: "Juventus",                away: "Inter Milan",          days: 4,  hour: 20, hs: 1.6, as: 1.9 },
  { league: "SA",  home: "AC Milan",                away: "Napoli",               days: 6,  hour: 20, hs: 1.7, as: 1.8 },
  { league: "SA",  home: "AS Roma",                 away: "Atalanta",             days: 10, hour: 18, hs: 1.5, as: 1.7 },

  # Ligue 1
  { league: "FL1", home: "Paris Saint-Germain",     away: "Olympique Marseille",  days: 5,  hour: 21, hs: 2.5, as: 1.4 },
  { league: "FL1", home: "AS Monaco",               away: "LOSC Lille",           days: 11, hour: 17, hs: 1.6, as: 1.5 },

  # Eredivisie
  { league: "DED", home: "Ajax",                    away: "PSV Eindhoven",        days: 6,  hour: 18, hs: 1.8, as: 2.0 },
  { league: "DED", home: "Feyenoord",               away: "AZ Alkmaar",           days: 12, hour: 16, hs: 1.7, as: 1.4 },

  # Champions League
  { league: "CL",  home: "Bayern München",          away: "Arsenal",              days: 6,  hour: 21, hs: 2.0, as: 1.8 },
  { league: "CL",  home: "Real Madrid",             away: "Inter Milan",          days: 7,  hour: 21, hs: 2.1, as: 1.7 },
]

upcoming_fixtures.each do |f|
  league = League.find_by(external_id: f[:league])
  next unless league
  home = Team.find_by(name: f[:home], league: league)
  away = Team.find_by(name: f[:away], league: league)
  next unless home && away

  kickoff = Time.current.beginning_of_day + f[:days].days + f[:hour].hours
  match = Match.find_or_create_by!(home_team: home, away_team: away, scheduled_at: kickoff) do |m|
    m.league = league
    m.status = :scheduled
  end
  build_prediction(match, f[:hs], f[:as])
end
puts "    ✓ Upcoming matches (#{Match.scheduled.count})"

# ── Recent finished matches (last 14 days) ───────────────────────────────────
recent_fixtures = [
  { league: "BL1", home: "Bayern München",   away: "Wolfsburg",          days: -3,  hs: 4, as: 0 },
  { league: "BL1", home: "RB Leipzig",       away: "SC Freiburg",        days: -3,  hs: 2, as: 1 },
  { league: "BL1", home: "VfB Stuttgart",    away: "Augsburg",           days: -4,  hs: 1, as: 1 },
  { league: "BL1", home: "Werder Bremen",    away: "Mainz 05",           days: -4,  hs: 3, as: 0 },
  { league: "PL",  home: "Manchester City",  away: "Fulham",             days: -2,  hs: 3, as: 1 },
  { league: "PL",  home: "Arsenal",          away: "Crystal Palace",     days: -2,  hs: 2, as: 0 },
  { league: "PL",  home: "Liverpool",        away: "Everton",            days: -5,  hs: 2, as: 0 },
  { league: "PL",  home: "Chelsea",          away: "Brentford",          days: -5,  hs: 1, as: 2 },
  { league: "PD",  home: "Real Madrid",      away: "Osasuna",            days: -3,  hs: 3, as: 1 },
  { league: "PD",  home: "FC Barcelona",     away: "Celta Vigo",         days: -4,  hs: 4, as: 2 },
  { league: "SA",  home: "Inter Milan",      away: "Udinese",            days: -2,  hs: 2, as: 0 },
  { league: "SA",  home: "Napoli",           away: "Lecce",              days: -6,  hs: 3, as: 0 },
  { league: "FL1", home: "Paris Saint-Germain", away: "Nantes",          days: -4,  hs: 5, as: 0 },
  { league: "CL",  home: "Bayern München",   away: "Borussia Dortmund",  days: -7,  hs: 2, as: 1 },
  { league: "CL",  home: "Real Madrid",      away: "Manchester City",    days: -8,  hs: 1, as: 1 },
]

recent_fixtures.each do |f|
  league = League.find_by(external_id: f[:league])
  next unless league
  home = Team.find_by(name: f[:home], league: league)
  away = Team.find_by(name: f[:away], league: league)
  next unless home && away

  kickoff = Time.current + f[:days].days - 2.hours
  Match.find_or_create_by!(home_team: home, away_team: away,
                            scheduled_at: kickoff.beginning_of_hour) do |m|
    m.league     = league
    m.status     = :finished
    m.home_score = f[:hs]
    m.away_score = f[:as]
  end
end
puts "    ✓ Recent results (#{Match.finished.count})"
puts "    ✓ Predictions (#{Prediction.count})"
