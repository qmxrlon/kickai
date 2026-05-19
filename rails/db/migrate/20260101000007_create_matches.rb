class CreateMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :matches do |t|
      t.references :league,    null: false, foreign_key: true
      t.references :home_team, null: false, foreign_key: { to_table: :teams }
      t.references :away_team, null: false, foreign_key: { to_table: :teams }

      t.string   :external_id
      t.datetime :scheduled_at,  null: false
      t.integer  :status,        null: false, default: 0
      t.integer  :home_score
      t.integer  :away_score
      t.jsonb    :raw_data,      default: {}
      t.string   :season

      t.timestamps
    end

    add_index :matches, :external_id,   unique: true, where: "external_id IS NOT NULL"
    add_index :matches, :scheduled_at
    add_index :matches, :status
    add_index :matches, %i[league_id status scheduled_at]
    add_index :matches, %i[home_team_id scheduled_at]
    add_index :matches, %i[away_team_id scheduled_at]
  end
end
