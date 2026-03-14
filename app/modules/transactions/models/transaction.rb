module Transactions
  module Models
    class Transaction < ApplicationRecord
      self.table_name = "transactions"

      belongs_to :user,   class_name: "Accounts::Models::User"
      belongs_to :wallet, class_name: "Wallets::Models::Wallet"

      validates :amount, numericality: { greater_than: 0 }
      validates :fee, numericality: { greater_than_or_equal_to: 0 }
      validates :t_type, inclusion: { in: %w[deposit withdrawal transfer payment refund] }
      validates :status, inclusion: { in: %w[pending successful failed] }
      validates :reference, presence: true, uniqueness: true
      validates :description, presence: true

      before_validation :generate_reference, on: :create

      scope :successful, -> { where(status: "successful") }
      scope :pending,    -> { where(status: "pending") }
      scope :failed,     -> { where(status: "failed") }

      private

      def generate_reference
        self.reference ||= "TXN-#{SecureRandom.alphanumeric(12).upcase}"
      end
    end
  end
end
