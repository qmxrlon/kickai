FactoryBot.define do
  factory :sport do
    sequence(:name) { |n| "Sport #{n}" }
    sequence(:slug) { |n| "sport-#{n}" }
  end

  factory :league do
    sport
    sequence(:name) { |n| "Liga #{n}" }
    country { "Deutschland" }
    sequence(:external_id) { |n| "L#{n}" }
  end

  factory :team do
    league
    sequence(:name) { |n| "Team #{n}" }
  end

  factory :match do
    league
    home_team { association :team, league: league }
    away_team { association :team, league: league }
    scheduled_at { 2.days.from_now }
    status { :scheduled }
  end

  factory :prediction do
    match
    home_win_prob { 0.5 }
    draw_prob { 0.3 }
    away_win_prob { 0.2 }
    btts_prob { 0.55 }
    predicted_goals { 2.6 }
    xg_home { 1.5 }
    xg_away { 1.1 }
    confidence_score { 42.0 }
    value_rating { 3 }
    over_under_probs { { "1.5" => 0.8, "2.5" => 0.55, "3.5" => 0.3 } }
    recommended_bet { "Heimsieg" }
  end

  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Sicher!Passwort123" }
    confirmed_at { Time.current }
    role { :user }

    trait :premium do
      role { :premium }
    end

    trait :admin do
      role { :admin }
    end
  end
end
