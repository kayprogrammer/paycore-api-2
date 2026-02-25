module Api
  module V1
    module Accounts
      class AuthController < ApplicationController
        before_action :authenticate_user!, only: [ :me ]

        def register
          user = ::Accounts::Models::User.new(register_params)

          if user.save
            token = Common::Utils::JwtService.encode(user_id: user.id)
            render_success(
              data: { user: ::Accounts::Schemas::UserSchema.call(user), token: token },
              message: "Registration successful",
              status: :created
            )
          else
            render_error(
              message: "Registration failed",
              errors: user.errors.full_messages,
              status: :unprocessable_entity
            )
          end
        end

        def login
          user = ::Accounts::Models::User.active.find_by!(email: params[:email]&.downcase)

          if user.authenticate(params[:password])
            token = Common::Utils::JwtService.encode(user_id: user.id)
            render_success(data: { user: ::Accounts::Schemas::UserSchema.call(user), token: token })
          else
            render_error(message: "Invalid credentials", status: :unauthorized)
          end
        end

        def me
          render_success(data: { user: ::Accounts::Schemas::UserSchema.call(current_user) })
        end

        private

        def register_params
          params.permit(:name, :email, :password, :password_confirmation)
        end
      end
    end
  end
end
