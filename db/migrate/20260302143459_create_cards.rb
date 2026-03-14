class CreateCards < ActiveRecord::Migration[8.1]
  def change
    create_table :cards, id: :uuid do |t|
      t.references :user,   null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :wallet, null: false, foreign_key: { to_table: :wallets }, type: :uuid

      t.string :name_on_card, null: false
      t.string :card_number,  null: false     # Best practice: store only masked (e.g. 4111********1111)
      t.string :expiry,       null: false     # "MM/YY"
      t.string :cvv,          null: false     # Might not store in prod, but keeping for parity/mocking
      t.string :brand,        null: false     # "Visa", "Mastercard"
      t.string :c_type,       null: false     # "virtual" or "physical"
      t.string :status,       null: false, default: "active" # "active", "frozen", "terminated"

      # External references for the card provider (Flutterwave / Sudo Africa)
      t.string :provider,         null: false # "flutterwave" or "sudo_africa"
      t.string :provider_card_id, null: false # ID returned by the provider

      t.timestamps
    end

    add_index :cards, :provider_card_id, unique: true
    add_index :cards, :user_id
  end
end
