class CreateBills < ActiveRecord::Migration[8.1]
  def change
    # e.g., "Airtime", "Electricity", "Internet", "Water"
    create_table :bill_categories, id: :uuid do |t|
      t.string  :name,      null: false
      t.string  :slug,      null: false
      t.string  :icon_url
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :bill_categories, :slug, unique: true

    # e.g., "MTN Nigeria", "Ikeja Electric"
    create_table :bill_providers, id: :uuid do |t|
      t.references :bill_category, null: false, foreign_key: true, type: :uuid
      t.string     :name,          null: false
      t.string     :slug,          null: false
      t.string     :logo_url
      t.boolean    :is_active,     null: false, default: true

      # External ID to map to Flutterwave's biller_code / item_code
      t.string     :provider_code, null: false

      t.timestamps
    end

    add_index :bill_providers, :slug, unique: true

    create_table :bill_payments, id: :uuid do |t|
      t.references :user,          null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :wallet,        null: false, foreign_key: { to_table: :wallets }, type: :uuid
      t.references :bill_provider, null: false, foreign_key: true, type: :uuid

      t.decimal :amount, null: false, precision: 20, scale: 8
      t.decimal :fee,    null: false, precision: 20, scale: 8, default: 0

      t.string  :customer_id, null: false # e.g., phone number, meter number
      t.string  :status,      null: false, default: "pending" # pending, successful, failed
      t.string  :reference,   null: false

      t.jsonb   :metadata, default: {} # Store external gateway ref, validation info, etc.

      t.timestamps
    end

    add_index :bill_payments, :reference, unique: true
    add_index :bill_payments, :customer_id
  end
end
