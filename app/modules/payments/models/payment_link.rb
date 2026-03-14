module Payments
  module Models
    class PaymentLink < ApplicationRecord
      self.table_name = "payment_links"

      belongs_to :user,   class_name: "Accounts::Models::User"
      belongs_to :wallet, class_name: "Wallets::Models::Wallet"

      validates :title, :link_url, presence: true
      validates :link_url, uniqueness: true
      validates :amount, numericality: { greater_than: 0 }, allow_nil: true # nil means customer pays any amount

      scope :active, -> { where(is_active: true) }

      before_validation :generate_link_slug, on: :create

      private

      def generate_link_slug
        self.link_url ||= SecureRandom.hex(6)
      end
    end
  end
end
