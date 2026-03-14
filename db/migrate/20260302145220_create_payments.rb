class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    # ----------------------------------------------------------------- #
    # Payment Links — Reusable links for accepting payments (donations)  #
    # ----------------------------------------------------------------- #
    create_table :payment_links, id: :uuid do |t|
      t.references :user,     null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :wallet,   null: false, foreign_key: { to_table: :wallets }, type: :uuid

      t.string  :title,       null: false
      t.text    :description
      t.decimal :amount,      precision: 20, scale: 8 # if nil, the customer enters the amount
      t.string  :link_url,    null: false             # the generated slug/URL segment
      t.boolean :is_active,   null: false, default: true

      t.timestamps
    end

    add_index :payment_links, :link_url, unique: true

    # ----------------------------------------------------------------- #
    # Invoices — Specific bills sent to specific customers              #
    # ----------------------------------------------------------------- #
    create_table :invoices, id: :uuid do |t|
      t.references :user,   null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :wallet, null: false, foreign_key: { to_table: :wallets }, type: :uuid

      t.string  :customer_name,  null: false
      t.string  :customer_email, null: false
      t.date    :due_date,       null: false
      t.decimal :subtotal,       null: false, default: 0, precision: 20, scale: 8
      t.decimal :tax_rate,       null: false, default: 0, precision: 5, scale: 2 # e.g., 7.5%
      t.decimal :total,          null: false, default: 0, precision: 20, scale: 8

      t.string  :status,         null: false, default: "draft" # draft, sent, paid, overdue, cancelled
      t.string  :invoice_number, null: false

      t.timestamps
    end

    add_index :invoices, :invoice_number, unique: true
    add_index :invoices, :customer_email

    # ----------------------------------------------------------------- #
    # Invoice Items — Line items inside an invoice                      #
    # ----------------------------------------------------------------- #
    create_table :invoice_items, id: :uuid do |t|
      t.references :invoice, null: false, foreign_key: true, type: :uuid

      t.string  :name,       null: false
      t.integer :quantity,   null: false, default: 1
      t.decimal :unit_price, null: false, precision: 20, scale: 8
      t.decimal :amount,     null: false, precision: 20, scale: 8 # quantity * unit_price

      t.timestamps
    end
  end
end
