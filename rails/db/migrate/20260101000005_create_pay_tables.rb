class CreatePayTables < ActiveRecord::Migration[8.0]
  def change
    # Pay customers (links users to payment processors)
    create_table :pay_customers do |t|
      t.belongs_to :owner, polymorphic: true, index: false
      t.string     :processor,     null: false
      t.string     :processor_id
      t.boolean    :default,       null: false, default: true
      t.jsonb      :data,          default: {}
      t.datetime   :deleted_at
      t.timestamps
    end
    add_index :pay_customers, %i[owner_type owner_id processor default], name: "pay_customers_owner_processor_default"
    add_index :pay_customers, %i[processor processor_id]

    # Subscriptions
    create_table :pay_subscriptions do |t|
      t.belongs_to :customer,  null: false
      t.string     :name,       null: false
      t.string     :processor_id, null: false
      t.string     :processor_plan, null: false
      t.integer    :quantity,   null: false, default: 1
      t.string     :status,     null: false
      t.datetime   :trial_ends_at
      t.datetime   :ends_at
      t.boolean    :metered
      t.string     :pause_behavior
      t.datetime   :pause_resumes_at
      t.decimal    :application_fee_percent, precision: 8, scale: 2
      t.jsonb      :data,       default: {}
      t.timestamps
    end
    add_index :pay_subscriptions, %i[customer_id processor_id], unique: true

    # Charges
    create_table :pay_charges do |t|
      t.belongs_to :customer,  null: false
      t.belongs_to :subscription, null: true
      t.string     :processor_id, null: false
      t.integer    :amount,     null: false
      t.integer    :amount_refunded, default: 0
      t.string     :currency
      t.string     :application_fee_amount
      t.boolean    :captured,   null: false, default: true
      t.jsonb      :data,       default: {}
      t.datetime   :created_at, null: false
      t.datetime   :updated_at, null: false
    end
    add_index :pay_charges, %i[customer_id processor_id], unique: true

    # Webhooks
    create_table :pay_webhooks do |t|
      t.string   :processor
      t.string   :event_type
      t.jsonb    :event,    null: false, default: {}
      t.timestamps
    end

    # Merchants
    create_table :pay_merchants do |t|
      t.belongs_to :owner, polymorphic: true, index: false
      t.string     :processor,    null: false
      t.string     :processor_id
      t.boolean    :default,      null: false, default: true
      t.jsonb      :data,         default: {}
      t.timestamps
    end
    add_index :pay_merchants, %i[owner_type owner_id processor default], name: "pay_merchants_owner_processor_default"
  end
end
