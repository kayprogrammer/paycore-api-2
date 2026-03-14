module Loans
  module Models
    class LoanRepayment < ApplicationRecord
      self.table_name = "loan_repayments"

      belongs_to :loan_application, class_name: "Loans::Models::LoanApplication"
      belongs_to :transaction_record, class_name: "Transactions::Models::Transaction", foreign_key: :transaction_id

      validates :amount, numericality: { greater_than: 0 }
    end
  end
end
