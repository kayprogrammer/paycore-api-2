module Api
  module V1
    module Bills
      class BillsController < ApplicationController
        before_action :authenticate_user!
        include Pagy::Backend

        # GET /api/v1/bills/providers
        # Returns all active bill categories with their providers
        def providers
          categories = ::Bills::Models::BillCategory.active.includes(:providers)
          render_success(
            data: {
              categories: categories.map { |c| ::Bills::Schemas::BillSchema.category_with_providers(c) }
            }
          )
        end

        # GET /api/v1/bills/history
        # Returns paginated bill payment history
        def history
          payments = ::Bills::Models::BillPayment
                       .where(user: current_user)
                       .includes(:provider)
                       .order(created_at: :desc)

          pagy, paginated = pagy(payments, limit: 20)

          render_success(
            data: {
              payments: ::Bills::Schemas::BillSchema.payment_collection(paginated),
              pagination: {
                count:    pagy.count,
                page:     pagy.page,
                pages:    pagy.pages,
                per_page: pagy.limit
              }
            }
          )
        end

        # POST /api/v1/bills/pay
        # Initiates a bill payment
        def pay
          payment, error = ::Bills::Services::BillService.pay_bill!(
            user:          current_user,
            currency_code: params[:currency],
            provider_slug: params[:provider_slug],
            amount:        params[:amount].to_f,
            customer_id:   params[:customer_id],
            pin:           params[:pin]
          )

          if error
            render_error(message: error, status: :bad_request)
          else
            render_success(
              data: { payment: ::Bills::Schemas::BillSchema.payment(payment) },
              message: "Bill payment successful"
            )
          end
        end
      end
    end
  end
end
