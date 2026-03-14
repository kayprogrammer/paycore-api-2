module Wallets
  module Models
    class Wallet < ApplicationRecord
      self.table_name = "wallets"

      belongs_to :user,     class_name: "Accounts::Models::User"
      belongs_to :currency, class_name: "Wallets::Models::Currency"

      validates :balance, numericality: { greater_than_or_equal_to: 0 }
      validates :user_id, uniqueness: { scope: :currency_id, message: "already has a wallet for this currency" }

      scope :active,    -> { where(is_active: true) }
      scope :unlocked,  -> { where(is_locked: false) }

      # ---------------------------------------------------------------- #
      # PIN management (stored as bcrypt digest, like has_secure_password) #
      # ---------------------------------------------------------------- #

      def set_pin(plain_pin)
        raise ArgumentError, "PIN must be 4 digits" unless plain_pin.to_s.match?(/\A\d{4}\z/)
        self.pin_digest = BCrypt::Password.create(plain_pin)
        save!
      end

      def authenticate_pin(plain_pin)
        return false if pin_digest.blank?
        BCrypt::Password.new(pin_digest) == plain_pin.to_s
      end

      def pin_set?
        pin_digest.present?
      end

      # ---------------------------------------------------------------- #
      # Balance helpers (all amounts in the wallet's native currency)      #
      # ---------------------------------------------------------------- #

      def credit!(amount)
        raise ArgumentError, "Amount must be positive" unless amount > 0
        with_lock { update!(balance: balance + amount) }
      end

      def debit!(amount)
        raise ArgumentError, "Amount must be positive" unless amount > 0
        raise "Insufficient balance" if balance < amount
        with_lock { update!(balance: balance - amount) }
      end
    end
  end
end
