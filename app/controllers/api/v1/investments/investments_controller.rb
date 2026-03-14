module Api
  module V1
    module Investments
      class InvestmentsController < ApplicationController
        before_action :authenticate_user!
        include Pagy::Backend

        # GET /api/v1/investments/products
        def products
          products = ::Investments::Models::InvestmentProduct.active
          render_success(data: { products: ::Investments::Schemas::InvestmentSchema.product_collection(products) })
        end

        # GET /api/v1/investments/
        # User's active/completed investments
        def index
          invs = current_user.investments.includes(:investment_product).order(created_at: :desc)
          pagy, paginated = pagy(invs, limit: 20)

          render_success(
            data: {
              investments: ::Investments::Schemas::InvestmentSchema.investment_collection(paginated),
              pagination: {
                count:    pagy.count,
                page:     pagy.page,
                pages:    pagy.pages,
                per_page: pagy.limit
              }
            }
          )
        end

        # POST /api/v1/investments/invest
        def invest
          inv, error = ::Investments::Services::InvestmentService.invest!(
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
              data: { investment: ::Investments::Schemas::InvestmentSchema.investment(inv) },
              message: "Investment started successfully!"
            )
          end
        end

        # POST /api/v1/investments/withdraw
        def withdraw
          earning, error = ::Investments::Services::InvestmentService.withdraw!(
            user:          current_user,
            investment_id: params[:investment_id]
          )

          if error
            render_error(message: error, status: :bad_request)
          else
            render_success(
              data: { payout: ::Investments::Schemas::InvestmentSchema.earning(earning) },
              message: "Investment withdrawn successfully! Funds have been credited to your wallet."
            )
          end
        end
      end
    end
  end
end
