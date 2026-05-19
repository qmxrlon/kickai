class CreateSports < ActiveRecord::Migration[8.0]
  def change
    create_table :sports do |t|
      t.string  :name,   null: false
      t.string  :slug,   null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :sports, :slug,   unique: true
    add_index :sports, :active
  end
end
