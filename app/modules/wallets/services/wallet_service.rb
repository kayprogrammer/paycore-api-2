module Wallets
  module Services
    class WalletService
      # Provisions wallets for all active currencies for a user.
      # Called after account verification is complete.
      def self.provision_wallets_for(user)
        Wallets::Models::Currency.active.find_each do |currency|
          Wallets::Models::Wallet.find_or_create_by!(user: user, currency: currency)
        end
      end

      # Finds or raises a not-found error for a user's wallet by currency code.
      def self.find_wallet!(user, currency_code)
        currency = Wallets::Models::Currency.find_by_code!(currency_code)
        user.wallets.active.find_by!(currency: currency)
      rescue ActiveRecord::RecordNotFound
        raise ActiveRecord::RecordNotFound, "Wallet not found for currency #{currency_code.upcase}"
      end

      # Executes an atomic wallet-to-wallet transfer within a DB transaction.
      # Raises on insufficient balance or locked wallets.
      def self.transfer!(from_wallet:, to_wallet:, amount:, pin:)
        raise "wallet is locked" if from_wallet.is_locked? || to_wallet.is_locked?
        raise "PIN required to transfer funds" unless from_wallet.pin_set?
        raise "Invalid PIN" unless from_wallet.authenticate_pin(pin)
        raise "Insufficient balance" if from_wallet.balance < amount

        ActiveRecord::Base.transaction do
          from_wallet.debit!(amount)
          to_wallet.credit!(amount)
        end
      end
    end
  end
end
