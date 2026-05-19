class CreateBettingTips < ActiveRecord::Migration[8.0]
  def change
    create_table :betting_tips do |t|
      t.references :match,  null: false, foreign_key: true
      t.references :user,   null: false, foreign_key: true
      t.integer :tip_type,  null: false, default: 0
      t.string  :tip_value, null: false
      t.decimal :odds,      null: false, precision: 6, scale: 2
      t.decimal :stake,     precision: 8, scale: 2
      t.integer :result,    null: false, default: 0
      t.boolean :published, null: false, default: false
      t.text    :notes
      t.timestamps
    end

    add_index :betting_tips, %i[user_id result]
    add_index :betting_tips, :published
  end
end
