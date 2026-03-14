module Investments
  module Services
    class InvestmentService
      # ------------------------------------------------------------- #
      # Create Investment                                             #
      # Locks up funds by debiting the user's wallet.                 #
      # ------------------------------------------------------------- #
      def self.invest!(user:, currency_code:, product_id:, amount:, pin:)
        wallet = ::Wallets::Services::WalletService.find_wallet!(user, currency_code)
        product = Investments::Models::InvestmentProduct.active.find(product_id)

        raise "Wallet is locked" if wallet.is_locked?
        raise "PIN not set" unless wallet.pin_set?
        raise "Invalid PIN" unless wallet.authenticate_pin(pin)
        raise "Insufficient balance" if wallet.balance < amount

        investment = nil
        ActiveRecord::Base.transaction do
          # 1. Debit the wallet (money goes into PayCore's holding/investment pool)
          wallet.debit!(amount)

          # 2. Record ledger transaction
          Transactions::Models::Transaction.create!(
            user:        user,
            wallet:      wallet,
            t_type:      "payment",
            amount:      amount,
            fee:         0,
            status:      "successful",
            description: "Investment in #{product.name}"
          )

          # 3. Create active investment record
          investment = Investments::Models::Investment.create!(
            user:               user,
            wallet:             wallet,
            investment_product: product,
            amount_invested:    amount,
            status:             "active"
          )

          # 4. Notify User
          Notifications::Models::Notification.notify(
            user:  user,
            ntype: "investment_started",
            title: "Investment Started",
            body:  "You have successfully invested #{wallet.currency.symbol}#{amount} in #{product.name}."
          )
        end

        [ investment, nil ]
      rescue ActiveRecord::RecordNotFound
        [ nil, "Investment product not found" ]
      rescue StandardError => e
        [ nil, e.message ]
      end

      # ------------------------------------------------------------- #
      # Withdraw Investment                                           #
      # Can only be done if the current date is >= end_date.          #
      # Pays out principal + interest via a credit ledger transaction.#
      # ------------------------------------------------------------- #
      def self.withdraw!(user:, investment_id:)
        investment = user.investments.includes(:wallet, :investment_product).find(investment_id)
        wallet = investment.wallet

        raise "Investment is not active" unless investment.status == "active"
        if Date.current < investment.end_date
          raise "Investment has not reached maturity date (#{investment.end_date})"
        end

        earning_record = nil
        payout_amount = investment.expected_return

        ActiveRecord::Base.transaction do
          # 1. Mark investment complete
          investment.update!(status: "completed")

          # 2. Credit the user's wallet (Principal + Interest)
          wallet.credit!(payout_amount)

          # 3. Record ledger transaction
          txn = Transactions::Models::Transaction.create!(
            user:        user,
            wallet:      wallet,
            t_type:      "deposit",
            amount:      payout_amount,
            fee:         0,
            status:      "successful",
            description: "Investment maturity payout for #{investment.investment_product.name}"
          )

          # 4. Record the earning detail
          earning_record = Investments::Models::InvestmentEarning.create!(
            investment:         investment,
            transaction_record: txn,
            amount:             payout_amount
          )

          # 5. Notify the user
          Notifications::Models::Notification.notify(
            user:  user,
            ntype: "investment_matured",
            title: "Investment Matured!",
            body:  "Your investment matured! #{wallet.currency.symbol}#{payout_amount} has been credited to your wallet."
          )
        end

        [ earning_record, nil ]
      rescue ActiveRecord::RecordNotFound
        [ nil, "Investment not found" ]
      rescue StandardError => e
        [ nil, e.message ]
      end
    end
  end
end
