module Api
  module V1
    module Wallets
      class WalletsController < ApplicationController
        before_action :authenticate_user!

        # GET /api/v1/wallets/
        # Returns all active wallets for the current user.
        def index
          wallets = current_user.wallets.active.includes(:currency)
          render_success(
            data: { wallets: ::Wallets::Schemas::WalletSchema.collection(wallets) }
          )
        end

        # GET /api/v1/wallets/:currency
        # Returns a specific wallet by its currency code (e.g., NGN).
        def show
          wallet = ::Wallets::Services::WalletService.find_wallet!(current_user, params[:currency])
          render_success(
            data: { wallet: ::Wallets::Schemas::WalletSchema.call(wallet) }
          )
        end

        # POST /api/v1/wallets/set-pin
        # Sets the 4-digit PIN for all wallets for the first time.
        def set_pin
          pin = params[:pin].to_s

          unless pin.match?(/\A\d{4}\z/)
            return render_error(message: "PIN must be exactly 4 digits", status: :bad_request)
          end

          if current_user.wallets.any?(&:pin_set?)
            return render_error(message: "PIN already set. Use change-pin instead.", status: :bad_request)
          end

          # Set PIN across all wallets the user owns
          ActiveRecord::Base.transaction do
            current_user.wallets.each { |w| w.set_pin(pin) }
          end

          render_success(message: "PIN set successfully")
        end

        # POST /api/v1/wallets/change-pin
        # Changes the 4-digit PIN (requires old_pin).
        def change_pin
          old_pin = params[:old_pin].to_s
          new_pin = params[:new_pin].to_s

          unless new_pin.match?(/\A\d{4}\z/)
            return render_error(message: "New PIN must be exactly 4 digits", status: :bad_request)
          end

          wallet = current_user.wallets.first
          return render_error(message: "No wallets found", status: :not_found) unless wallet

          unless wallet.pin_set?
            return render_error(message: "PIN not set yet. Use set-pin instead.", status: :bad_request)
          end

          unless wallet.authenticate_pin(old_pin)
            return render_error(message: "Incorrect old PIN", status: :unauthorized)
          end

          # Update PIN across all wallets
          ActiveRecord::Base.transaction do
            current_user.wallets.each { |w| w.set_pin(new_pin) }
          end

          render_success(message: "PIN changed successfully")
        end

        # GET /api/v1/wallets/rates
        # Returns all pairwise exchange rates as a nested JSON object.
        def rates
          rates_map = ::Wallets::Models::ExchangeRate.as_map
          render_success(data: { rates: rates_map })
        end
      end
    end
  end
end
