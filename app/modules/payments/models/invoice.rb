module Payments
  module Models
    class Invoice < ApplicationRecord
      self.table_name = "invoices"

      belongs_to :user,   class_name: "Accounts::Models::User"
      belongs_to :wallet, class_name: "Wallets::Models::Wallet"
      has_many   :items,  class_name: "Payments::Models::InvoiceItem", foreign_key: :invoice_id, dependent: :destroy

      validates :customer_name, :customer_email, :due_date, :invoice_number, presence: true
      validates :invoice_number, uniqueness: true
      validates :status, inclusion: { in: %w[draft sent paid overdue cancelled] }

      validates :subtotal, :total, numericality: { greater_than_or_equal_to: 0 }
      validates :tax_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

      before_validation :generate_invoice_number, on: :create
      before_save :calculate_totals

      # Accepts nested attributes so we can create items exactly when we create the invoice
      accepts_nested_attributes_for :items

      private

      def generate_invoice_number
        return if invoice_number.present?
        # Generates something like INV-A1B2C3
        self.invoice_number = "INV-#{SecureRandom.alphanumeric(6).upcase}"
      end

      # Automatically sums up items and applies the tax rate (e.g. 7.5%) before saving
      def calculate_totals
        self.subtotal = items.reject(&:marked_for_destruction?).sum(&:amount)
        calculated_tax = (self.subtotal * (self.tax_rate / 100.0)).round(2)
        self.total = self.subtotal + calculated_tax
      end
    end
  end
end
