class CreatePredictions < ActiveRecord::Migration[8.0]
  def change
    create_table :predictions do |t|
      t.references :match, null: false, foreign_key: true, index: { unique: true }

      # 1X2 probabilities
      t.decimal :home_win_prob, precision: 5, scale: 4
      t.decimal :draw_prob,     precision: 5, scale: 4
      t.decimal :away_win_prob, precision: 5, scale: 4

      # Over/Under { "over_15_prob": 0.85, "over_25_prob": 0.61, "over_35_prob": 0.38 }
      t.jsonb   :over_under_probs, default: {}

      # BTTS
      t.decimal :btts_prob, precision: 5, scale: 4

      # xG
      t.decimal :xg_home, precision: 5, scale: 2
      t.decimal :xg_away, precision: 5, scale: 2
      t.decimal :predicted_goals, precision: 5, scale: 2

      # Meta
      t.decimal :confidence_score, precision: 5, scale: 2   # 0-100
      t.integer :value_rating                                # 1-5
      t.string  :recommended_bet
      t.decimal :kelly_fraction, precision: 5, scale: 4

      # AI text
      t.text    :ai_analysis

      # Model versioning
      t.string  :model_version, default: "1.0"

      t.timestamps
    end

    add_index :predictions, :confidence_score
    add_index :predictions, :created_at
  end
end
