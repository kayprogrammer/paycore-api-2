module Api
  module V1
    module Loans
      class LoansController < ApplicationController
        before_action :authenticate_user!
        include Pagy::Backend

        # GET /api/v1/loans/products
        def products
          products = ::Loans::Models::LoanProduct.active
          render_success(data: { products: ::Loans::Schemas::LoanSchema.product_collection(products) })
        end

        # GET /api/v1/loans/
        # User's loan history
        def index
          apps = current_user.loan_applications.includes(:loan_product).order(created_at: :desc)
          pagy, paginated = pagy(apps, limit: 20)

          render_success(
            data: {
              loans: ::Loans::Schemas::LoanSchema.application_collection(paginated),
              pagination: {
                count:    pagy.count,
                page:     pagy.page,
                pages:    pagy.pages,
                per_page: pagy.limit
              }
            }
          )
        end

        # GET /api/v1/loans/:id/repayments
        def repayments
          app = current_user.loan_applications.find(params[:id])
          repayments = app.repayments.includes(:transaction_record).order(created_at: :desc)

          pagy, paginated = pagy(repayments, limit: 20)

          render_success(
            data: {
              repayments: ::Loans::Schemas::LoanSchema.repayment_collection(paginated),
              pagination: {
                count:    pagy.count,
                page:     pagy.page,
                pages:    pagy.pages,
                per_page: pagy.limit
              }
            }
          )
        rescue ActiveRecord::RecordNotFound
          render_error(message: "Loan application not found", status: :not_found)
        end

        # POST /api/v1/loans/apply
        def apply
          app, error = ::Loans::Services::LoanService.apply!(
            user:          current_user,
            currency_code: params[:currency],
            product_id:    params[:product_id],
            amount:        params[:amount].to_f,
            pin:           params[:pin]
          )

          if error
            render_error(message: error, status: :bad_request)
          else
            render_success(
              data: { loan: ::Loans::Schemas::LoanSchema.application(app) },
              message: app.status == "active" ? "Loan approved and disbursed!" : "Loan application received"
            )
          end
        end

        # POST /api/v1/loans/repay
        def repay
          rep, error = ::Loans::Services::LoanService.repay!(
            user:           current_user,
            application_id: params[:application_id],
            amount:         params[:amount].to_f,
            pin:            params[:pin]
          )

          if error
            render_error(message: error, status: :bad_request)
          else
            render_success(
              data: { repayment: ::Loans::Schemas::LoanSchema.repayment(rep) },
              message: "Repayment successful"
            )
          end
        end
      end
    end
  end
end
