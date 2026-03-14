module Wallets
  module Schemas
    class WalletSchema
      def self.call(wallet)
        {
          id:          wallet.id,
          currency:    {
            code:   wallet.currency.code,
            name:   wallet.currency.name,
            symbol: wallet.currency.symbol,
            flag:   wallet.currency.flag
          },
          balance:     wallet.balance.to_f,
          is_locked:   wallet.is_locked,
          is_active:   wallet.is_active,
          pin_set:     wallet.pin_set?,
          created_at:  wallet.created_at
        }
      end

      def self.collection(wallets)
        wallets.map { |w| call(w) }
      end
    end
  end
end
