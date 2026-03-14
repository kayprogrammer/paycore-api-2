module Api
  module V1
    module Payments
      class InvoicesController < ApplicationController
        before_action :authenticate_user!
        include Pagy::Backend

        # GET /api/v1/payments/invoices/
        def index
          invoices = current_user.invoices.includes(:items, wallet: :currency).order(created_at: :desc)
          pagy, paginated = pagy(invoices, limit: 20)

          render_success(
            data: {
              invoices: ::Payments::Schemas::PaymentSchema.invoice_collection(paginated),
              pagination: {
                count:    pagy.count,
                page:     pagy.page,
                pages:    pagy.pages,
                per_page: pagy.limit
              }
            }
          )
        end

        # GET /api/v1/payments/invoices/:id
        def show
          invoice = current_user.invoices.find(params[:id])
          render_success(data: { invoice: ::Payments::Schemas::PaymentSchema.invoice(invoice) })
        rescue ActiveRecord::RecordNotFound
          render_error(message: "Invoice not found", status: :not_found)
        end

        # POST /api/v1/payments/invoices/
        def create
          wallet = ::Wallets::Services::WalletService.find_wallet!(current_user, params[:currency])

          # `items` should be an array of hashes: [{ name: "Design", quantity: 1, unit_price: 50.0 }, ...]
          items_attributes = params.fetch(:items, []).map do |item|
            {
              name:       item[:name],
              quantity:   item[:quantity].to_i,
              unit_price: item[:unit_price].to_f
            }
          end

          invoice = current_user.invoices.create!(
            wallet:           wallet,
            customer_name:    params[:customer_name],
            customer_email:   params[:customer_email],
            due_date:         params[:due_date],
            tax_rate:         params[:tax_rate].to_f,
            items_attributes: items_attributes
          )

          render_success(
            data: { invoice: ::Payments::Schemas::PaymentSchema.invoice(invoice) },
            message: "Invoice created successfully",
            status: :created
          )
        rescue StandardError => e
          render_error(message: e.message, status: :bad_request)
        end
      end
    end
  end
end
