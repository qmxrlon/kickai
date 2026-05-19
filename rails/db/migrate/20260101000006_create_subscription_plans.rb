class CreateSubscriptionPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_plans do |t|
      t.string  :name,                null: false
      t.integer :tier,                null: false, default: 0
      t.integer :price_monthly_cents, null: false, default: 0
      t.string  :currency,            null: false, default: "EUR"
      t.jsonb   :features,            null: false, default: {}
      t.boolean :active,              null: false, default: true
      t.timestamps
    end

    add_index :subscription_plans, :tier
    add_index :subscription_plans, :active
  end
end
