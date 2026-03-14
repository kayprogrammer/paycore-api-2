class CreateLoans < ActiveRecord::Migration[8.1]
  def change
    create_table :loan_products, id: :uuid do |t|
      t.string  :name,          null: false
      t.text    :description
      t.decimal :interest_rate, null: false, precision: 5, scale: 2 # e.g. 5.5%
      t.integer :duration_days, null: false
      t.boolean :is_active,     null: false, default: true

      t.timestamps
    end

    create_table :loan_applications, id: :uuid do |t|
      t.references :user,         null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :wallet,       null: false, foreign_key: { to_table: :wallets }, type: :uuid
      t.references :loan_product, null: false, foreign_key: true, type: :uuid

      t.decimal :amount,           null: false, precision: 20, scale: 8
      t.decimal :amount_to_repay,  null: false, precision: 20, scale: 8
      t.decimal :amount_repaid,    null: false, default: 0, precision: 20, scale: 8

      t.string  :status,           null: false, default: "pending" # pending, approved, rejected, active, completed, defaulted
      t.date    :due_date

      t.text    :rejection_reason

      t.timestamps
    end

    add_index :loan_applications, :status
    add_index :loan_applications, :due_date

    create_table :loan_repayments, id: :uuid do |t|
      t.references :loan_application, null: false, foreign_key: true, type: :uuid
      t.references :transaction,      null: false, foreign_key: { to_table: :transactions }, type: :uuid # The ledger record

      t.decimal :amount, null: false, precision: 20, scale: 8

      t.timestamps
    end
  end
end
