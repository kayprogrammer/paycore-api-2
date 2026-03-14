module Investments
  module Models
    class InvestmentEarning < ApplicationRecord
      self.table_name = "investment_earnings"

      belongs_to :investment,         class_name: "Investments::Models::Investment"
      belongs_to :transaction_record, class_name: "Transactions::Models::Transaction", foreign_key: :transaction_id

      validates :amount, numericality: { greater_than: 0 }
    end
  end
end
