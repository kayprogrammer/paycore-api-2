module Loans
  module Models
    class LoanApplication < ApplicationRecord
      self.table_name = "loan_applications"

      belongs_to :user,         class_name: "Accounts::Models::User"
      belongs_to :wallet,       class_name: "Wallets::Models::Wallet"
      belongs_to :loan_product, class_name: "Loans::Models::LoanProduct"
      has_many   :repayments,   class_name: "Loans::Models::LoanRepayment", foreign_key: :loan_application_id

      validates :amount, numericality: { greater_than: 0 }
      validates :amount_to_repay, :amount_repaid, numericality: { greater_than_or_equal_to: 0 }
      validates :status, inclusion: { in: %w[pending approved rejected active completed defaulted] }

      before_validation :calculate_repayment_amount, on: :create

      def repay!(repayment_amount)
        with_lock do
          self.amount_repaid += repayment_amount
          self.status = "completed" if amount_repaid >= amount_to_repay
          save!
        end
      end

      private

      # Calculates Total Amount = Principal + (Principal * Rate%)
      def calculate_repayment_amount
        return unless amount && loan_product
        interest = amount * (loan_product.interest_rate / 100.0)
        self.amount_to_repay = amount + interest
      end
    end
  end
end
