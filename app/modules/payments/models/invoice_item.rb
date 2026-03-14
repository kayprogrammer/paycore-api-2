module Payments
  module Models
    class InvoiceItem < ApplicationRecord
      self.table_name = "invoice_items"

      belongs_to :invoice, class_name: "Payments::Models::Invoice"

      validates :name, presence: true
      validates :quantity, numericality: { only_integer: true, greater_than: 0 }
      validates :unit_price, numericality: { greater_than_or_equal_to: 0 }

      before_save :calculate_amount

      private

      def calculate_amount
        self.amount = quantity * unit_price
      end
    end
  end
end
