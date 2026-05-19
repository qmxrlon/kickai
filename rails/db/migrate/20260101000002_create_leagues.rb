class CreateLeagues < ActiveRecord::Migration[8.0]
  def change
    create_table :leagues do |t|
      t.references :sport, null: false, foreign_key: true
      t.string  :name,              null: false
      t.string  :country,           null: false
      t.string  :external_id
      t.string  :logo_url
      t.boolean :active,            null: false, default: true
      t.jsonb   :standings_cache,   default: {}
      t.datetime :standings_cached_at
      t.timestamps
    end

    add_index :leagues, :external_id, unique: true, where: "external_id IS NOT NULL"
    add_index :leagues, :active
    add_index :leagues, %i[sport_id active]
  end
end
