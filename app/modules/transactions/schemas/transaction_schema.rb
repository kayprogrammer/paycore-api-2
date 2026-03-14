module Transactions
  module Schemas
    class TransactionSchema
      def self.call(transaction)
        {
          id:          transaction.id,
          type:        transaction.t_type,
          amount:      transaction.amount.to_f,
          fee:         transaction.fee.to_f,
          status:      transaction.status,
          reference:   transaction.reference,
          description: transaction.description,
          metadata:    transaction.metadata,
          created_at:  transaction.created_at,
          user:        transaction.user ? basic_user_info(transaction.user) : nil,
          wallet:      transaction.wallet ? basic_wallet_info(transaction.wallet) : nil
        }
      end

      def self.collection(transactions)
        transactions.map { |t| call(t) }
      end

      private

      def self.basic_user_info(user)
        {
          id:         user.id,
          first_name: user.first_name,
          last_name:  user.last_name,
          email:      user.email
        }
      end

      def self.basic_wallet_info(wallet)
        {
          currency: wallet.currency.code
        }
      end
    end
  end
end
