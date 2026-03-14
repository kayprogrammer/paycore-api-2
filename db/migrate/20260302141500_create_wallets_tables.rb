class CreateWalletsTables < ActiveRecord::Migration[8.1]
  def change
    # -------------------------------------------------------------- #
    # Currencies — supported currency codes and metadata              #
    # -------------------------------------------------------------- #
    create_table :currencies, id: :uuid do |t|
      t.string  :code,     null: false, limit: 10  # e.g. "NGN", "USD"
      t.string  :name,     null: false              # e.g. "Nigerian Naira"
      t.string  :symbol,   null: false, limit: 10  # e.g. "₦"
      t.string  :flag,                              # emoji or URL e.g. "🇳🇬"
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :currencies, :code, unique: true

    # Seed the four supported currencies right in the migration
    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO currencies (id, code, name, symbol, flag, is_active, created_at, updated_at)
          VALUES
            (gen_random_uuid(), 'NGN', 'Nigerian Naira',   '₦', '🇳🇬', true, NOW(), NOW()),
            (gen_random_uuid(), 'KES', 'Kenyan Shilling',  'KSh', '🇰🇪', true, NOW(), NOW()),
            (gen_random_uuid(), 'GHS', 'Ghanaian Cedi',    '₵', '🇬🇭', true, NOW(), NOW()),
            (gen_random_uuid(), 'USD', 'US Dollar',        '$', '🇺🇸', true, NOW(), NOW())
        SQL
      end
    end

    # -------------------------------------------------------------- #
    # Exchange rates — refreshed periodically by a background job     #
    # -------------------------------------------------------------- #
    create_table :exchange_rates, id: :uuid do |t|
      t.references :from_currency, null: false, foreign_key: { to_table: :currencies }, type: :uuid
      t.references :to_currency,   null: false, foreign_key: { to_table: :currencies }, type: :uuid
      t.decimal    :rate,          null: false, precision: 20, scale: 8
      t.datetime   :fetched_at,    null: false

      t.timestamps
    end

    add_index :exchange_rates, [ :from_currency_id, :to_currency_id ], unique: true

    # -------------------------------------------------------------- #
    # Wallets — one wallet per user per currency                      #
    # -------------------------------------------------------------- #
    create_table :wallets, id: :uuid do |t|
      t.references :user,     null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :currency, null: false, foreign_key: { to_table: :currencies }, type: :uuid
      t.decimal    :balance,  null: false, default: 0, precision: 20, scale: 8
      t.string     :pin_digest              # bcrypt digest of the 4-digit PIN
      t.boolean    :is_locked, null: false, default: false
      t.boolean    :is_active, null: false, default: true

      t.timestamps
    end

    add_index :wallets, [ :user_id, :currency_id ], unique: true
  end
end
