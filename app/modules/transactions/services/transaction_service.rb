module Transactions
  module Services
    class TransactionService
      # ------------------------------------------------------------- #
      # Deposit                                                       #
      # Initializes a pending deposit. External gateways like         #
      # Flutterwave will hit a webhook to mark this successful.       #
      # ------------------------------------------------------------- #
      def self.initiate_deposit!(user:, currency_code:, amount:)
        wallet = ::Wallets::Services::WalletService.find_wallet!(user, currency_code)

        txn = Transactions::Models::Transaction.create!(
          user:        user,
          wallet:      wallet,
          t_type:      "deposit",
          amount:      amount,
          fee:         0, # Deposits are usually free or fee is taken externally
          status:      "pending",
          description: "Wallet deposit via external gateway"
        )
        [ txn, nil ]
      rescue StandardError => e
        [ nil, e.message ]
      end

      def self.complete_deposit!(reference:)
        txn = Transactions::Models::Transaction.pending.find_by(reference: reference)
        return [ nil, "Pending deposit not found" ] unless txn

        ActiveRecord::Base.transaction do
          txn.wallet.credit!(txn.amount)
          txn.update!(status: "successful")

          Notifications::Models::Notification.notify(
            user:     txn.user,
            ntype:    "deposit_successful",
            title:    "Deposit Successful",
            body:     "Your deposit of #{txn.wallet.currency.symbol}#{txn.amount} has been credited to your wallet.",
            metadata: { transaction_ref: txn.reference }
          )
        end
        [ txn, nil ]
      rescue StandardError => e
        [ nil, e.message ]
      end

      # ------------------------------------------------------------- #
      # Withdrawal                                                    #
      # Debits the wallet immediately, marks pending until external   #
      # payout service confirms success.                              #
      # ------------------------------------------------------------- #
      def self.initiate_withdrawal!(user:, currency_code:, amount:, pin:, bank_code:, account_number:)
        wallet = ::Wallets::Services::WalletService.find_wallet!(user, currency_code)

        raise "Wallet is locked" if wallet.is_locked?
        raise "PIN not set" unless wallet.pin_set?
        raise "Invalid PIN" unless wallet.authenticate_pin(pin)

        # Simple flat fee for withdrawal example
        fee = 50.0
        total_deduction = amount + fee

        raise "Insufficient balance" if wallet.balance < total_deduction

        txn = nil
        ActiveRecord::Base.transaction do
          wallet.debit!(total_deduction)

          txn = Transactions::Models::Transaction.create!(
            user:        user,
            wallet:      wallet,
            t_type:      "withdrawal",
            amount:      amount,
            fee:         fee,
            status:      "pending",
            description: "Bank payout to #{account_number}",
            metadata:    { bank_code: bank_code, account_number: account_number }
          )
        end
        [ txn, nil ]
      rescue StandardError => e
        [ nil, e.message ]
      end

      # ------------------------------------------------------------- #
      # Internal Transfer (P2P)                                       #
      # Atomic movement of funds between users in the same currency.  #
      # ------------------------------------------------------------- #
      def self.transfer!(sender:, recipient_email:, currency_code:, amount:, pin:, description:)
        recipient = Accounts::Models::User.active.find_by(email: recipient_email.downcase)
        return [ nil, "Recipient not found" ] unless recipient
        return [ nil, "Cannot transfer to yourself" ] if sender.id == recipient.id

        sender_wallet = ::Wallets::Services::WalletService.find_wallet!(sender, currency_code)
        recipient_wallet = ::Wallets::Services::WalletService.find_wallet!(recipient, currency_code)

        raise "Your wallet is locked" if sender_wallet.is_locked?
        raise "Recipient wallet is locked" if recipient_wallet.is_locked?
        raise "Invalid PIN" unless sender_wallet.authenticate_pin(pin)
        raise "Insufficient balance" if sender_wallet.balance < amount

        sender_txn = nil
        ActiveRecord::Base.transaction do
          # 1. Move the money
          sender_wallet.debit!(amount)
          recipient_wallet.credit!(amount)

          # 2. Record sender transaction
          sender_txn = Transactions::Models::Transaction.create!(
            user:        sender,
            wallet:      sender_wallet,
            t_type:      "transfer",
            amount:      amount,
            fee:         0, # P2P is free
            status:      "successful",
            description: description || "Transfer to #{recipient.first_name}",
            metadata:    { recipient_email: recipient.email, recipient_id: recipient.id }
          )

          # 3. Record recipient transaction
          Transactions::Models::Transaction.create!(
            user:        recipient,
            wallet:      recipient_wallet,
            t_type:      "transfer",
            amount:      amount,
            fee:         0,
            status:      "successful",
            description: "Transfer from #{sender.first_name}",
            metadata:    { sender_email: sender.email, sender_id: sender.id, paired_ref: sender_txn.reference }
          )

          # 4. Notify both parties
          Notifications::Models::Notification.notify(
            user:     sender,
            ntype:    "transfer_sent",
            title:    "Transfer Sent",
            body:     "You sent #{sender_wallet.currency.symbol}#{amount} to #{recipient.first_name}.",
            metadata: { transaction_ref: sender_txn.reference }
          )

          Notifications::Models::Notification.notify(
            user:     recipient,
            ntype:    "transfer_received",
            title:    "Money Received!",
            body:     "#{sender.first_name} sent you #{recipient_wallet.currency.symbol}#{amount}.",
            metadata: { sender_name: sender.first_name }
          )
        end

        [ sender_txn, nil ]
      rescue StandardError => e
        [ nil, e.message ]
      end
    end
  end
end
