class CreateInvestments < ActiveRecord::Migration[8.1]
  def change
    create_table :investment_products, id: :uuid do |t|
      t.string  :name,          null: false
      t.text    :description
      t.decimal :interest_rate, null: false, precision: 5, scale: 2 # e.g. 10.5%
      t.integer :duration_days, null: false
      t.boolean :is_active,     null: false, default: true

      t.timestamps
    end

    create_table :investments, id: :uuid do |t|
      t.references :user,               null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :wallet,             null: false, foreign_key: { to_table: :wallets }, type: :uuid
      t.references :investment_product, null: false, foreign_key: true, type: :uuid

      t.decimal :amount_invested, null: false, precision: 20, scale: 8
      t.decimal :expected_return, null: false, precision: 20, scale: 8

      t.string  :status,      null: false, default: "active" # active, completed, prematurely_withdrawn
      t.date    :start_date,  null: false
      t.date    :end_date,    null: false

      t.timestamps
    end

    add_index :investments, :status
    add_index :investments, :end_date

    create_table :investment_earnings, id: :uuid do |t|
      t.references :investment,  null: false, foreign_key: true, type: :uuid
      t.references :transaction, null: false, foreign_key: { to_table: :transactions }, type: :uuid # The ledger record

      t.decimal :amount, null: false, precision: 20, scale: 8

      t.timestamps
    end
  end
end
