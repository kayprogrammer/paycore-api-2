module Bills
  module Models
    class BillPayment < ApplicationRecord
      self.table_name = "bill_payments"

      belongs_to :user,     class_name: "Accounts::Models::User"
      belongs_to :wallet,   class_name: "Wallets::Models::Wallet"
      belongs_to :provider, class_name: "Bills::Models::BillProvider", foreign_key: :bill_provider_id

      validates :amount, numericality: { greater_than: 0 }
      validates :customer_id, :reference, presence: true
      validates :reference, uniqueness: true
      validates :status, inclusion: { in: %w[pending successful failed] }

      before_validation :generate_reference, on: :create

      private

      def generate_reference
        self.reference ||= "BIL-#{SecureRandom.alphanumeric(12).upcase}"
      end
    end
  end
end
