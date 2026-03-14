module Api
  module V1
    module Cards
      class CardsController < ApplicationController
        before_action :authenticate_user!

        # GET /api/v1/cards/
        def index
          cards = current_user.cards.includes(wallet: :currency).order(created_at: :desc)
          render_success(data: { cards: ::Cards::Schemas::CardSchema.collection(cards) })
        end

        # POST /api/v1/cards/create
        def create_virtual
          card, error = ::Cards::Services::CardService.create_virtual_card!(
            user:           current_user,
            currency_code:  params[:currency],
            name_on_card:   params[:name_on_card],
            amount_to_fund: params[:amount_to_fund].to_f
          )

          if error
            render_error(message: error, status: :bad_request)
          else
            render_success(
              data: { card: ::Cards::Schemas::CardSchema.call(card) },
              message: "Virtual card created successfully",
              status: :created
            )
          end
        end

        # POST /api/v1/cards/:id/freeze
        def freeze
          card, error = ::Cards::Services::CardService.freeze_card!(current_user, params[:id])

          if error
            render_error(message: error, status: :bad_request)
          else
            render_success(
              data: { card: ::Cards::Schemas::CardSchema.call(card) },
              message: "Card frozen successfully"
            )
          end
        end

        # POST /api/v1/cards/:id/unfreeze
        def unfreeze
          card, error = ::Cards::Services::CardService.unfreeze_card!(current_user, params[:id])

          if error
            render_error(message: error, status: :bad_request)
          else
            render_success(
              data: { card: ::Cards::Schemas::CardSchema.call(card) },
              message: "Card unfrozen successfully"
            )
          end
        end

        # DELETE /api/v1/cards/:id
        def destroy
          card, error = ::Cards::Services::CardService.terminate_card!(current_user, params[:id])

          if error
            render_error(message: error, status: :bad_request)
          else
            render_success(
              data: { card: ::Cards::Schemas::CardSchema.call(card) },
              message: "Card terminated successfully"
            )
          end
        end
      end
    end
  end
end
