module Api
  module V1
    module Transactions
      class TransactionsController < ApplicationController
        before_action :authenticate_user!
        include Pagy::Backend

        # GET /api/v1/transactions/
        # Returns paginated list of the user's transactions (newest first).
        def index
          txns = ::Transactions::Models::Transaction
                   .where(user: current_user)
                   .includes(:wallet)
                   .order(created_at: :desc)

          # Optional filter by currency
          if params[:currency].present?
            currency = Wallets::Models::Currency.find_by_code!(params[:currency])
            txns = txns.where(wallet_id: currency.wallets.select(:id))
          end

          # Optional filter by type
          if params[:type].present?
            txns = txns.where(t_type: params[:type])
          end

          pagy, paginated = pagy(txns, limit: 20)

          render_success(
            data: {
              transactions: ::Transactions::Schemas::TransactionSchema.collection(paginated),
              pagination: {
                count:    pagy.count,
                page:     pagy.page,
                pages:    pagy.pages,
                per_page: pagy.limit
              }
            }
          )
        end

        # GET /api/v1/transactions/:reference
        def show
          txn = ::Transactions::Models::Transaction
                  .where(user: current_user)
                  .find_by!(reference: params[:reference])

          render_success(data: { transaction: ::Transactions::Schemas::TransactionSchema.call(txn) })
        end

        # POST /api/v1/transactions/deposit
        def deposit
          txn, error = ::Transactions::Services::TransactionService.initiate_deposit!(
            user:          current_user,
            currency_code: params[:currency],
            amount:        params[:amount].to_f
          )

          if error
            render_error(message: error, status: :bad_request)
          else
            render_success(
              data: { transaction: ::Transactions::Schemas::TransactionSchema.call(txn) },
              message: "Deposit initiated"
            )
          end
        end

        # POST /api/v1/transactions/withdraw
        def withdraw
          txn, error = ::Transactions::Services::TransactionService.initiate_withdrawal!(
            user:           current_user,
            currency_code:  params[:currency],
            amount:         params[:amount].to_f,
            pin:            params[:pin],
            bank_code:      params[:bank_code],
            account_number: params[:account_number]
          )

          if error
            render_error(message: error, status: :bad_request)
          else
            render_success(
              data: { transaction: ::Transactions::Schemas::TransactionSchema.call(txn) },
              message: "Withdrawal processing"
            )
          end
        end

        # POST /api/v1/transactions/transfer
        def transfer
          txn, error = ::Transactions::Services::TransactionService.transfer!(
            sender:          current_user,
            recipient_email: params[:recipient_email],
            currency_code:   params[:currency],
            amount:          params[:amount].to_f,
            pin:             params[:pin],
            description:     params[:description]
          )

          if error
            render_error(message: error, status: :bad_request)
          else
            render_success(
              data: { transaction: ::Transactions::Schemas::TransactionSchema.call(txn) },
              message: "Transfer successful"
            )
          end
        end
      end
    end
  end
end
