# db/seeds.rb — Seeds sports, leagues, and subscription plans.
# Idempotent: safe to run multiple times.

puts "Seeding database..."

# ── Sports ───────────────────────────────────────────────────────────────────
sports_data = [
  { name: "Fußball",    slug: "football" },
  { name: "Tennis",     slug: "tennis" },
  { name: "Basketball", slug: "basketball" }
]
sports_data.each { |s| Sport.find_or_create_by!(slug: s[:slug]) { |r| r.name = s[:name] } }
puts "  ✓ Sports (#{Sport.count})"

football = Sport.find_by!(slug: "football")

# ── Leagues (Football-Data.org competition IDs) ───────────────────────────────
leagues_data = [
  { name: "Bundesliga",           country: "Deutschland", external_id: "BL1" },
  { name: "2. Bundesliga",        country: "Deutschland", external_id: "BL2" },
  { name: "Premier League",       country: "England",     external_id: "PL"  },
  { name: "Primera División",     country: "Spanien",     external_id: "PD"  },
  { name: "Serie A",              country: "Italien",     external_id: "SA"  },
  { name: "Ligue 1",              country: "Frankreich",  external_id: "FL1" },
  { name: "Eredivisie",           country: "Niederlande", external_id: "DED" },
  { name: "Primeira Liga",        country: "Portugal",    external_id: "PPL" },
  { name: "UEFA Champions League",country: "Europa",      external_id: "CL"  }
]
leagues_data.each do |l|
  League.find_or_create_by!(external_id: l[:external_id]) do |r|
    r.name    = l[:name]
    r.country = l[:country]
    r.sport   = football
    r.active  = true
  end
end
puts "  ✓ Leagues (#{League.count})"

# ── Subscription plans ────────────────────────────────────────────────────────
plans = [
  {
    name: "Kostenlos",
    tier: :free,
    price_monthly_cents: 0,
    features: {
      "match_list"      => true,
      "predictions_1x2" => false,
      "over_under"      => false,
      "btts"            => false,
      "xg_display"      => false,
      "kelly"           => false,
      "ai_analysis"     => false,
      "all_leagues"     => false
    }
  },
  {
    name: "Basic",
    tier: :basic,
    price_monthly_cents: 999,
    features: {
      "match_list"      => true,
      "predictions_1x2" => true,
      "over_under"      => true,
      "btts"            => true,
      "xg_display"      => false,
      "kelly"           => false,
      "ai_analysis"     => false,
      "all_leagues"     => true
    }
  },
  {
    name: "Premium",
    tier: :premium,
    price_monthly_cents: 1999,
    features: {
      "match_list"      => true,
      "predictions_1x2" => true,
      "over_under"      => true,
      "btts"            => true,
      "xg_display"      => true,
      "kelly"           => true,
      "ai_analysis"     => true,
      "all_leagues"     => true
    }
  }
]

plans.each do |p|
  SubscriptionPlan.find_or_create_by!(name: p[:name]) do |r|
    r.tier                = p[:tier]
    r.price_monthly_cents = p[:price_monthly_cents]
    r.features            = p[:features]
    r.active              = true
  end
end
puts "  ✓ Subscription plans (#{SubscriptionPlan.count})"

# ── Admin user (only in development / first boot) ─────────────────────────────
if Rails.env.development? && User.none?
  User.create!(
    name:                  "Admin",
    email:                 "admin@kickai.local",
    password:              "kickai_dev_password",
    password_confirmation: "kickai_dev_password",
    role:                  :admin,
    confirmed_at:          Time.current
  )
  puts "  ✓ Admin user created (admin@kickai.local / kickai_dev_password)"
end

# ── Dev match data (teams, upcoming matches, predictions) ─────────────────────
if Rails.env.development?
  load Rails.root.join("db/seeds/dev_data.rb")
end

puts "Seeding complete."
