module Api
  module V1
    module Payments
      class PaymentLinksController < ApplicationController
        before_action :authenticate_user!
        include Pagy::Backend

        # GET /api/v1/payments/links/
        def index
          links = current_user.payment_links.includes(wallet: :currency).order(created_at: :desc)
          pagy, paginated = pagy(links, limit: 20)

          render_success(
            data: {
              payment_links: ::Payments::Schemas::PaymentSchema.link_collection(paginated),
              pagination: {
                count:    pagy.count,
                page:     pagy.page,
                pages:    pagy.pages,
                per_page: pagy.limit
              }
            }
          )
        end

        # GET /api/v1/payments/links/:id
        def show
          link = current_user.payment_links.find(params[:id])
          render_success(data: { payment_link: ::Payments::Schemas::PaymentSchema.link(link) })
        rescue ActiveRecord::RecordNotFound
          render_error(message: "Payment link not found", status: :not_found)
        end

        # POST /api/v1/payments/links/
        def create
          wallet = ::Wallets::Services::WalletService.find_wallet!(current_user, params[:currency])

          link = current_user.payment_links.create!(
            wallet:      wallet,
            title:       params[:title],
            description: params[:description],
            amount:      params[:amount]
          )

          render_success(
            data: { payment_link: ::Payments::Schemas::PaymentSchema.link(link) },
            message: "Payment link created successfully",
            status: :created
          )
        rescue StandardError => e
          render_error(message: e.message, status: :bad_request)
        end
      end
    end
  end
end
