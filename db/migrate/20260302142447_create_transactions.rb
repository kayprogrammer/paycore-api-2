class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions, id: :uuid do |t|
      t.references :user,   null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :wallet, null: false, foreign_key: { to_table: :wallets }, type: :uuid

      t.decimal :amount, null: false, precision: 20, scale: 8
      t.decimal :fee,    null: false, default: 0, precision: 20, scale: 8

      t.string :t_type,      null: false               # deposit, withdrawal, transfer, payment, refund
      t.string :status,      null: false, default: "pending" # pending, successful, failed
      t.string :reference,   null: false               # Unique alphanumeric ref
      t.string :description, null: false

      t.jsonb :metadata, default: {}                   # Store sender/receiver details, external gateway refs, etc.

      t.timestamps
    end

    add_index :transactions, :reference, unique: true
    add_index :transactions, :t_type
    add_index :transactions, :status
    add_index :transactions, [ :user_id, :created_at ]
  end
end
