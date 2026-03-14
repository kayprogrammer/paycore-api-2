module Investments
  module Models
    class Investment < ApplicationRecord
      self.table_name = "investments"

      belongs_to :user,               class_name: "Accounts::Models::User"
      belongs_to :wallet,             class_name: "Wallets::Models::Wallet"
      belongs_to :investment_product, class_name: "Investments::Models::InvestmentProduct"
      has_many   :earnings,           class_name: "Investments::Models::InvestmentEarning", foreign_key: :investment_id

      validates :amount_invested, numericality: { greater_than: 0 }
      validates :expected_return, numericality: { greater_than_or_equal_to: 0 }
      validates :status, inclusion: { in: %w[active completed prematurely_withdrawn] }
      validates :start_date, :end_date, presence: true

      before_validation :calculate_investment_metrics, on: :create

      private

      def calculate_investment_metrics
        return unless amount_invested && investment_product

        self.start_date ||= Date.current
        self.end_date   ||= self.start_date + investment_product.duration_days.days

        # Simple interest for mockup: Principal + (Principal * Rate%)
        interest = amount_invested * (investment_product.interest_rate / 100.0)
        self.expected_return = amount_invested + interest
      end
    end
  end
end
