module Api
  module V1
    module Accounts
      class AuthController < ApplicationController
        before_action :authenticate_user!, only: [ :me, :logout, :biometrics_enable, :biometrics_disable ]

        # ---------------------------------------------------------------- #
        # POST /api/v1/accounts/auth/register                               #
        # Creates account. Sends OTP verification email.                    #
        # ---------------------------------------------------------------- #
        def register
          if ::Accounts::Models::User.exists?(email: params[:email]&.downcase)
            return render_error(
              message: "Registration failed",
              errors: [ "Email already registered" ],
              status: :unprocessable_entity
            )
          end

          user = ::Accounts::Models::User.new(register_params)

          if user.save
            Accounts::SendOtpEmailJob.perform_later(user.id, "account verification")
            render_success(data: { email: user.email }, message: "Registration successful", status: :created)
          else
            render_error(message: "Registration failed", errors: user.errors.full_messages, status: :unprocessable_entity)
          end
        end

        # ---------------------------------------------------------------- #
        # POST /api/v1/accounts/auth/verify-email                           #
        # Verifies OTP → activates account → returns access+refresh tokens  #
        # ---------------------------------------------------------------- #
        def verify_email
          user = find_user_by_email(params[:email])
          return unless user

          return render_success(message: "Email already verified") if user.is_email_verified?

          otp = params[:otp].to_i
          return render_error(message: "Incorrect OTP", status: :not_found) if user.otp_code != otp
          return render_error(message: "OTP has expired", status: :gone) if user.otp_expired?

          user.update!(is_email_verified: true)
          user.clear_otp!

          # Provision wallets for the newly verified user
          ::Wallets::Services::WalletService.provision_wallets_for(user)

          AccountsMailer.welcome_email(user).deliver_later

          render_success(message: "Account verification successful")
        end

        # ---------------------------------------------------------------- #
        # POST /api/v1/accounts/auth/resend-verification-otp                #
        # ---------------------------------------------------------------- #
        def resend_verification_otp
          user = find_user_by_email(params[:email])
          return unless user

          return render_success(message: "Email already verified") if user.is_email_verified?

          Accounts::SendOtpEmailJob.perform_later(user.id, "account verification")
          render_success(message: "Verification email sent")
        end

        # ---------------------------------------------------------------- #
        # POST /api/v1/accounts/auth/send-password-reset-otp                #
        # ---------------------------------------------------------------- #
        def send_password_reset_otp
          user = find_user_by_email(params[:email])
          return unless user

          Accounts::SendOtpEmailJob.perform_later(user.id, "password reset")
          render_success(message: "Password reset OTP sent")
        end

        # ---------------------------------------------------------------- #
        # POST /api/v1/accounts/auth/set-new-password                       #
        # ---------------------------------------------------------------- #
        def set_new_password
          user = find_user_by_email(params[:email])
          return unless user

          otp = params[:otp].to_i
          return render_error(message: "Incorrect OTP", status: :not_found) if user.otp_code != otp
          return render_error(message: "OTP has expired", status: :gone) if user.otp_expired?

          user.password = params[:password]
          if user.save
            user.clear_otp!
            AccountsMailer.password_reset_confirmation(user).deliver_later
            render_success(message: "Password reset successful")
          else
            render_error(message: "Password update failed", errors: user.errors.full_messages, status: :unprocessable_entity)
          end
        end

        # ---------------------------------------------------------------- #
        # POST /api/v1/accounts/auth/login  (Step 1)                        #
        # Validates credentials, sends MFA OTP to email.                    #
        # ---------------------------------------------------------------- #
        def login
          user = ::Accounts::Models::User.active.find_by(email: params[:email]&.downcase)

          unless user&.authenticate(params[:password])
            return render_error(message: "Invalid credentials", status: :unauthorized)
          end

          unless user.is_email_verified?
            return render_error(message: "Verify your email first", status: :unauthorized)
          end

          Accounts::SendOtpEmailJob.perform_later(user.id, "login verification")
          render_success(message: "Login OTP sent to your email")
        end

        # ---------------------------------------------------------------- #
        # POST /api/v1/accounts/auth/login/verify  (Step 2)                 #
        # Verifies MFA OTP → returns access+refresh token pair.             #
        # ---------------------------------------------------------------- #
        def login_verify
          user = find_user_by_email(params[:email])
          return unless user

          unless user.is_email_verified?
            return render_error(message: "Verify your email first", status: :unauthorized)
          end

          otp = params[:otp].to_i
          return render_error(message: "Invalid OTP code", status: :unauthorized) if user.otp_code != otp
          return render_error(message: "OTP has expired", status: :gone) if user.otp_expired?

          user.clear_otp!
          access, refresh = ::Accounts::Services::AuthService.create_tokens_for_user(user)

          render_success(
            message: "Login successful",
            data: { access: access, refresh: refresh }
          )
        end

        # ---------------------------------------------------------------- #
        # POST /api/v1/accounts/auth/refresh                                #
        # Rotates the refresh token → new access+refresh pair.              #
        # ---------------------------------------------------------------- #
        def refresh
          refresh_token = params[:token]
          return render_error(message: "Refresh token not provided", status: :unauthorized) if refresh_token.blank?

          user, new_access, new_refresh = ::Accounts::Services::AuthService.rotate_refresh_token(refresh_token)

          unless user
            return render_error(message: "Refresh token is invalid or expired", status: :unauthorized)
          end

          render_success(data: { access: new_access, refresh: new_refresh }, message: "Tokens refreshed successfully")
        end

        # ---------------------------------------------------------------- #
        # POST /api/v1/accounts/auth/google-login                           #
        # Validates Google ID token, creates user if new.                   #
        # ---------------------------------------------------------------- #
        def google_login
          user_data = ::Accounts::Services::AuthService.validate_google_token(params[:token])

          unless user_data
            return render_error(message: "Invalid Google token", status: :unauthorized)
          end

          user = ::Accounts::Services::AuthService.find_or_create_google_user(
            user_data[:email], user_data[:name], user_data[:picture]
          )

          # Provision wallets for new Google users (if not already provisioned)
          ::Wallets::Services::WalletService.provision_wallets_for(user)

          access, refresh = ::Accounts::Services::AuthService.create_tokens_for_user(user)
          render_success(message: "Google login successful", data: { access: access, refresh: refresh })
        end

        # ---------------------------------------------------------------- #
        # POST /api/v1/accounts/auth/logout                                 #
        # Clears stored tokens → invalidates all sessions.                  #
        # ---------------------------------------------------------------- #
        def logout
          ::Accounts::Services::AuthService.invalidate_user_tokens(current_user)
          render_success(message: "Logout successful")
        end

        # ---------------------------------------------------------------- #
        # GET /api/v1/accounts/auth/me                                      #
        # ---------------------------------------------------------------- #
        def me
          render_success(data: { user: ::Accounts::Schemas::UserSchema.call(current_user) })
        end

        # ---------------------------------------------------------------- #
        # POST /api/v1/accounts/auth/biometrics/enable                      #
        # ---------------------------------------------------------------- #
        def biometrics_enable
          if current_user.biometrics_enabled?
            return render_error(message: "Biometrics already enabled for this account", status: :bad_request)
          end

          trust_token, expires_at = ::Accounts::Services::AuthService.create_trust_token(
            current_user, params[:device_id]
          )

          render_success(
            message: "Biometrics authentication enabled successfully",
            data: { trust_token: trust_token, expires_at: expires_at.iso8601 }
          )
        end

        # ---------------------------------------------------------------- #
        # POST /api/v1/accounts/auth/biometrics/login                       #
        # ---------------------------------------------------------------- #
        def biometrics_login
          user, error_msg = ::Accounts::Services::AuthService.validate_trust_token(
            params[:email], params[:trust_token], params[:device_id]
          )

          unless user
            return render_error(message: error_msg || "Invalid biometrics credentials", status: :unauthorized)
          end

          access, refresh = ::Accounts::Services::AuthService.create_tokens_for_user(user)
          render_success(message: "Biometrics login successful", data: { access: access, refresh: refresh })
        end

        # ---------------------------------------------------------------- #
        # POST /api/v1/accounts/auth/biometrics/disable                     #
        # ---------------------------------------------------------------- #
        def biometrics_disable
          unless current_user.biometrics_enabled?
            return render_error(message: "Biometrics not enabled for this account", status: :bad_request)
          end

          ::Accounts::Services::AuthService.revoke_trust_token(current_user)
          render_success(message: "Biometrics authentication disabled successfully")
        end

        private

        def register_params
          params.permit(:first_name, :last_name, :email, :password, :password_confirmation)
        end

        # Shared helper: find user by email, return 404 if not found.
        def find_user_by_email(email)
          user = ::Accounts::Models::User.find_by(email: email&.downcase)
          render_error(message: "Incorrect email", status: :not_found) unless user
          user
        end
      end
    end
  end
end
