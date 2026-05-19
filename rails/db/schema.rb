# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_01_000010) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "betting_tips", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "match_id", null: false
    t.text "notes"
    t.decimal "odds", precision: 6, scale: 2, null: false
    t.boolean "published", default: false, null: false
    t.integer "result", default: 0, null: false
    t.decimal "stake", precision: 8, scale: 2
    t.integer "tip_type", default: 0, null: false
    t.string "tip_value", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["match_id"], name: "index_betting_tips_on_match_id"
    t.index ["published"], name: "index_betting_tips_on_published"
    t.index ["user_id", "result"], name: "index_betting_tips_on_user_id_and_result"
    t.index ["user_id"], name: "index_betting_tips_on_user_id"
  end

  create_table "leagues", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "country", null: false
    t.datetime "created_at", null: false
    t.string "external_id"
    t.string "logo_url"
    t.string "name", null: false
    t.bigint "sport_id", null: false
    t.jsonb "standings_cache", default: {}
    t.datetime "standings_cached_at"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_leagues_on_active"
    t.index ["external_id"], name: "index_leagues_on_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["sport_id", "active"], name: "index_leagues_on_sport_id_and_active"
    t.index ["sport_id"], name: "index_leagues_on_sport_id"
  end

  create_table "match_statistics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "match_id", null: false
    t.jsonb "stats", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["match_id"], name: "index_match_statistics_on_match_id", unique: true
  end

  create_table "matches", force: :cascade do |t|
    t.integer "away_score"
    t.bigint "away_team_id", null: false
    t.datetime "created_at", null: false
    t.string "external_id"
    t.integer "home_score"
    t.bigint "home_team_id", null: false
    t.bigint "league_id", null: false
    t.jsonb "raw_data", default: {}
    t.datetime "scheduled_at", null: false
    t.string "season"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["away_team_id", "scheduled_at"], name: "index_matches_on_away_team_id_and_scheduled_at"
    t.index ["away_team_id"], name: "index_matches_on_away_team_id"
    t.index ["external_id"], name: "index_matches_on_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["home_team_id", "scheduled_at"], name: "index_matches_on_home_team_id_and_scheduled_at"
    t.index ["home_team_id"], name: "index_matches_on_home_team_id"
    t.index ["league_id", "status", "scheduled_at"], name: "index_matches_on_league_id_and_status_and_scheduled_at"
    t.index ["league_id"], name: "index_matches_on_league_id"
    t.index ["scheduled_at"], name: "index_matches_on_scheduled_at"
    t.index ["status"], name: "index_matches_on_status"
  end

  create_table "pay_charges", force: :cascade do |t|
    t.integer "amount", null: false
    t.integer "amount_refunded", default: 0
    t.string "application_fee_amount"
    t.boolean "captured", default: true, null: false
    t.datetime "created_at", null: false
    t.string "currency"
    t.bigint "customer_id", null: false
    t.jsonb "data", default: {}
    t.string "processor_id", null: false
    t.bigint "subscription_id"
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_charges_on_customer_id_and_processor_id", unique: true
    t.index ["customer_id"], name: "index_pay_charges_on_customer_id"
    t.index ["subscription_id"], name: "index_pay_charges_on_subscription_id"
  end

  create_table "pay_customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}
    t.boolean "default", default: true, null: false
    t.datetime "deleted_at"
    t.bigint "owner_id"
    t.string "owner_type"
    t.string "processor", null: false
    t.string "processor_id"
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "processor", "default"], name: "pay_customers_owner_processor_default"
    t.index ["processor", "processor_id"], name: "index_pay_customers_on_processor_and_processor_id"
  end

  create_table "pay_merchants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}
    t.boolean "default", default: true, null: false
    t.bigint "owner_id"
    t.string "owner_type"
    t.string "processor", null: false
    t.string "processor_id"
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "processor", "default"], name: "pay_merchants_owner_processor_default"
  end

  create_table "pay_subscriptions", force: :cascade do |t|
    t.decimal "application_fee_percent", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.jsonb "data", default: {}
    t.datetime "ends_at"
    t.boolean "metered"
    t.string "name", null: false
    t.string "pause_behavior"
    t.datetime "pause_resumes_at"
    t.string "processor_id", null: false
    t.string "processor_plan", null: false
    t.integer "quantity", default: 1, null: false
    t.string "status", null: false
    t.datetime "trial_ends_at"
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_subscriptions_on_customer_id_and_processor_id", unique: true
    t.index ["customer_id"], name: "index_pay_subscriptions_on_customer_id"
  end

  create_table "pay_webhooks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "event", default: {}, null: false
    t.string "event_type"
    t.string "processor"
    t.datetime "updated_at", null: false
  end

  create_table "predictions", force: :cascade do |t|
    t.text "ai_analysis"
    t.decimal "away_win_prob", precision: 5, scale: 4
    t.decimal "btts_prob", precision: 5, scale: 4
    t.decimal "confidence_score", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.decimal "draw_prob", precision: 5, scale: 4
    t.decimal "home_win_prob", precision: 5, scale: 4
    t.decimal "kelly_fraction", precision: 5, scale: 4
    t.bigint "match_id", null: false
    t.string "model_version", default: "1.0"
    t.jsonb "over_under_probs", default: {}
    t.decimal "predicted_goals", precision: 5, scale: 2
    t.string "recommended_bet"
    t.datetime "updated_at", null: false
    t.integer "value_rating"
    t.decimal "xg_away", precision: 5, scale: 2
    t.decimal "xg_home", precision: 5, scale: 2
    t.index ["confidence_score"], name: "index_predictions_on_confidence_score"
    t.index ["created_at"], name: "index_predictions_on_created_at"
    t.index ["match_id"], name: "index_predictions_on_match_id", unique: true
  end

  create_table "sports", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_sports_on_active"
    t.index ["slug"], name: "index_sports_on_slug", unique: true
  end

  create_table "subscription_plans", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.jsonb "features", default: {}, null: false
    t.string "name", null: false
    t.integer "price_monthly_cents", default: 0, null: false
    t.integer "tier", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_subscription_plans_on_active"
    t.index ["tier"], name: "index_subscription_plans_on_tier"
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "crest_url"
    t.string "external_id"
    t.bigint "league_id", null: false
    t.string "name", null: false
    t.string "short_name"
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_teams_on_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["league_id", "name"], name: "index_teams_on_league_id_and_name"
    t.index ["league_id"], name: "index_teams_on_league_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "betting_tips", "matches"
  add_foreign_key "betting_tips", "users"
  add_foreign_key "leagues", "sports"
  add_foreign_key "match_statistics", "matches"
  add_foreign_key "matches", "leagues"
  add_foreign_key "matches", "teams", column: "away_team_id"
  add_foreign_key "matches", "teams", column: "home_team_id"
  add_foreign_key "predictions", "matches"
  add_foreign_key "teams", "leagues"
end
