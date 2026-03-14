module Loans
  module Models
    class LoanProduct < ApplicationRecord
      self.table_name = "loan_products"

      validates :name, :interest_rate, :duration_days, presence: true
      validates :interest_rate, numericality: { greater_than_or_equal_to: 0 }
      validates :duration_days, numericality: { only_integer: true, greater_than: 0 }

      scope :active, -> { where(is_active: true) }
    end
  end
end
