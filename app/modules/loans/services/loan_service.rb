module Loans
  module Services
    class LoanService
      # ------------------------------------------------------------- #
      # Apply for Loan                                                #
      # Initializes a loan application. If auto-approved, the funds   #
      # are disbursed to the user's wallet immediately.               #
      # ------------------------------------------------------------- #
      def self.apply!(user:, currency_code:, product_id:, amount:, pin:)
        wallet = ::Wallets::Services::WalletService.find_wallet!(user, currency_code)
        product = Loans::Models::LoanProduct.active.find(product_id)

        raise "Wallet is locked" if wallet.is_locked?
        raise "PIN not set" unless wallet.pin_set?
        raise "Invalid PIN" unless wallet.authenticate_pin(pin)

        application = nil

        # For this mockup, we auto-approve loans under 50,000.
        auto_approve = amount <= 50_000

        ActiveRecord::Base.transaction do
          application = Loans::Models::LoanApplication.create!(
            user:         user,
            wallet:       wallet,
            loan_product: product,
            amount:       amount,
            status:       auto_approve ? "active" : "pending",
            due_date:     auto_approve ? Date.current + product.duration_days.days : nil
          )

          if auto_approve
            disburse_funds!(application: application, wallet: wallet, amount: amount)
          end
        end

        [ application, nil ]
      rescue ActiveRecord::RecordNotFound
        [ nil, "Loan product not found" ]
      rescue StandardError => e
        [ nil, e.message ]
      end

      # ------------------------------------------------------------- #
      # Make Repayment                                                #
      # Debits the user's wallet and credits the loan balance.        #
      # ------------------------------------------------------------- #
      def self.repay!(user:, application_id:, amount:, pin:)
        application = user.loan_applications.includes(:wallet).find(application_id)
        wallet = application.wallet

        raise "Loan is not active" unless application.status == "active"
        raise "Wallet is locked" if wallet.is_locked?
        raise "Invalid PIN" unless wallet.authenticate_pin(pin)

        # Do not allow overpayment
        remaining_balance = application.amount_to_repay - application.amount_repaid
        actual_repayment = [ amount, remaining_balance ].min

        raise "Insufficient balance in wallet" if wallet.balance < actual_repayment

        repayment = nil
        ActiveRecord::Base.transaction do
          # 1. Debit wallet
          wallet.debit!(actual_repayment)

          # 2. Record ledger transaction
          txn = Transactions::Models::Transaction.create!(
            user:        user,
            wallet:      wallet,
            t_type:      "payment",
            amount:      actual_repayment,
            fee:         0,
            status:      "successful",
            description: "Loan repayment for #{application.loan_product.name}"
          )

          # 3. Update loan balance
          application.repay!(actual_repayment)

          # 4. Create repayment record
          repayment = Loans::Models::LoanRepayment.create!(
            loan_application:   application,
            transaction_record: txn,
            amount:             actual_repayment
          )

          # 5. Notify user
          Notifications::Models::Notification.notify(
            user:  user,
            ntype: "loan_repayment",
            title: "Loan Repayment Successful",
            body:  "You repaid #{wallet.currency.symbol}#{actual_repayment}. #{application.status == 'completed' ? 'Your loan is fully paid off!' : ''}"
          )
        end

        [ repayment, nil ]
      rescue ActiveRecord::RecordNotFound
        [ nil, "Loan application not found" ]
      rescue StandardError => e
        [ nil, e.message ]
      end

      private

      def self.disburse_funds!(application:, wallet:, amount:)
        wallet.credit!(amount)

        Transactions::Models::Transaction.create!(
          user:        application.user,
          wallet:      wallet,
          t_type:      "deposit",
          amount:      amount,
          fee:         0,
          status:      "successful",
          description: "Loan disbursement: #{application.loan_product.name}"
        )

        Notifications::Models::Notification.notify(
          user:  application.user,
          ntype: "loan_approved",
          title: "Loan Approved",
          body:  "Your loan of #{wallet.currency.symbol}#{amount} has been disbursed."
        )
      end
    end
  end
end
