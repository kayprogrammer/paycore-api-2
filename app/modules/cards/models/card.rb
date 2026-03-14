module Cards
  module Models
    class Card < ApplicationRecord
      self.table_name = "cards"

      belongs_to :user,   class_name: "Accounts::Models::User"
      belongs_to :wallet, class_name: "Wallets::Models::Wallet"

      validates :name_on_card, :card_number, :expiry, :cvv, :brand, presence: true
      validates :provider, :provider_card_id, presence: true

      validates :c_type, inclusion:   { in: %w[virtual physical] }
      validates :status, inclusion:   { in: %w[active frozen terminated] }
      validates :provider, inclusion: { in: %w[flutterwave sudo_africa mock] }

      scope :active, -> { where(status: "active") }
      scope :frozen, -> { where(status: "frozen") }

      def active?
        status == "active"
      end

      def frozen?
        status == "frozen"
      end

      def terminated?
        status == "terminated"
      end

      def freeze!
        update!(status: "frozen")
      end

      def unfreeze!
        update!(status: "active")
      end

      def terminate!
        update!(status: "terminated")
      end

      # Returns the last 4 digits
      def last4
        card_number[-4..-1]
      end
    end
  end
end
