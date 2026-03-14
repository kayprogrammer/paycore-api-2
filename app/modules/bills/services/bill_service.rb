module Bills
  module Services
    class BillService
      # ------------------------------------------------------------- #
      # Pay Bill                                                      #
      # Initializes and processes a bill payment linked to a user     #
      # wallet. Simulates a provider API call.                        #
      # ------------------------------------------------------------- #
      def self.pay_bill!(user:, currency_code:, provider_slug:, amount:, customer_id:, pin:)
        wallet = ::Wallets::Services::WalletService.find_wallet!(user, currency_code)
        provider = Bills::Models::BillProvider.active.find_by!(slug: provider_slug)

        # Standard fee for bill payments (e.g. 50 flat)
        fee = 50.0
        total_deduction = amount + fee

        raise "Wallet is locked" if wallet.is_locked?
        raise "PIN not set" unless wallet.pin_set?
        raise "Invalid PIN" unless wallet.authenticate_pin(pin)
        raise "Insufficient balance" if wallet.balance < total_deduction

        # MOCK EXTERNAL API CALL (Flutterwave/Paystack)
        # response = FlutterwaveClient.pay_bill(
        #   biller_code: provider.provider_code,
        #   amount: amount,
        #   customer: customer_id
        # )

        # Simulate success
        payment = nil
        ActiveRecord::Base.transaction do
          # 1. Debit the wallet
          wallet.debit!(total_deduction)

          # 2. Record the ledger transaction
          txn = Transactions::Models::Transaction.create!(
            user:        user,
            wallet:      wallet,
            t_type:      "payment",
            amount:      amount,
            fee:         fee,
            status:      "successful",
            description: "Bill payment: #{provider.name} for #{customer_id}"
          )

          # 3. Create the specific BillPayment record
          payment = Bills::Models::BillPayment.create!(
            user:          user,
            wallet:        wallet,
            bill_provider: provider,
            amount:        amount,
            fee:           fee,
            customer_id:   customer_id,
            status:        "successful",
            metadata:      { transaction_ref: txn.reference, external_ref: "mock-ext-#{SecureRandom.hex(4)}" }
          )

          # 4. Notify user
          Notifications::Models::Notification.notify(
            user:     user,
            ntype:    "bill_payment_successful",
            title:    "Bill Paid",
            body:     "You successfully paid #{wallet.currency.symbol}#{amount} for #{provider.name}.",
            metadata: { bill_reference: payment.reference }
          )
        end

        [ payment, nil ]
      rescue StandardError => e
        [ nil, e.message ]
      end
    end
  end
end
