class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.references :league, null: false, foreign_key: true
      t.string :name,        null: false
      t.string :short_name
      t.string :external_id
      t.string :crest_url
      t.timestamps
    end

    add_index :teams, :external_id, unique: true, where: "external_id IS NOT NULL"
    add_index :teams, %i[league_id name]
  end
end
