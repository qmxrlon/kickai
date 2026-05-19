class CreateMatchStatistics < ActiveRecord::Migration[8.0]
  def change
    create_table :match_statistics do |t|
      t.references :match, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :stats, null: false, default: {}
      t.timestamps
    end
  end
end
