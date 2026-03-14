module Accounts
  module Services
    class AuthService
      # ------------------------------------------------------------------ #
      # Token management                                                     #
      # ------------------------------------------------------------------ #

      # Creates an access + refresh token pair and persists them on the user.
      # Storing tokens on the user record enables server-side revocation (logout).
      def self.create_tokens_for_user(user)
        access  = Common::Utils::JwtService.encode(user_id: user.id)
        refresh = Common::Utils::JwtService.encode_refresh(user_id: user.id)
        user.update!(access: access, refresh: refresh)
        [ access, refresh ]
      end

      # Validates the refresh token, checks it matches what we stored, then
      # issues a brand-new pair (rotation). Old tokens become invalid immediately.
      def self.rotate_refresh_token(refresh_token)
        payload = Common::Utils::JwtService.decode_refresh(refresh_token)
        user = Accounts::Models::User.active.find_by(id: payload[:user_id])

        # Ensure the token matches the stored one (prevents replay after logout)
        return [ nil, nil, nil ] unless user && user.refresh == refresh_token

        new_access, new_refresh = create_tokens_for_user(user)
        [ user, new_access, new_refresh ]
      rescue JWT::DecodeError
        [ nil, nil, nil ]
      end

      # Clears both tokens from the DB, invalidating all sessions immediately.
      def self.invalidate_user_tokens(user)
        user.update!(access: nil, refresh: nil)
      end

      # ------------------------------------------------------------------ #
      # Google OAuth                                                         #
      # ------------------------------------------------------------------ #

      def self.validate_google_token(id_token)
        require "googleauth"
        validator = Google::Auth::IDTokens
        payload   = validator.verify_oidc(id_token, aud: ENV.fetch("APP_GOOGLE_CLIENT_ID", nil))

        {
          email:   payload["email"],
          name:    payload["name"],
          picture: payload["picture"]
        }
      rescue Google::Auth::IDTokens::SignatureError,
             Google::Auth::IDTokens::AuthorizedPartyError,
             Google::Auth::IDTokens::ExpiredTokenError => e
        Rails.logger.warn("Google token validation failed: #{e.message}")
        nil
      end

      # Finds or creates a Google-authenticated user.
      def self.find_or_create_google_user(email, name, picture_url)
        user = Accounts::Models::User.find_by(email: email.downcase)

        if user
          # Update avatar from Google if they don't have one yet
          user.update!(social_avatar: picture_url) if user.social_avatar.blank? && picture_url.present?
          return user
        end

        first_name, *rest = name.to_s.split(" ")
        last_name = rest.join(" ").presence || first_name

        Accounts::Models::User.create!(
          email:              email.downcase,
          first_name:         first_name,
          last_name:          last_name,
          social_avatar:      picture_url,
          is_email_verified:  true,       # Google already verified the email
          password:           SecureRandom.hex(24) # Random non-guessable password
        )
      end

      # ------------------------------------------------------------------ #
      # Trust tokens (biometrics)                                            #
      # ------------------------------------------------------------------ #

      # Creates a signed trust token tied to a device_id and stores it on the user.
      def self.create_trust_token(user, device_id)
        raw_token    = SecureRandom.hex(32)
        expires_at   = 30.days.from_now
        # Store as "device_id:raw_token" so we can scope it to the device
        trust_string = "#{device_id}:#{raw_token}"
        user.update!(
          trust_token:            trust_string,
          trust_token_expires_at: expires_at,
          biometrics_enabled:     true
        )
        [ raw_token, expires_at ]
      end

      # Validates a trust token against the stored value for the given device.
      def self.validate_trust_token(email, raw_token, device_id)
        user = Accounts::Models::User.active.find_by(email: email.downcase)
        return [ nil, "User not found" ] unless user
        return [ nil, "Biometrics not enabled" ] unless user.biometrics_enabled?
        return [ nil, "Trust token expired" ] if user.trust_token_expired?

        expected = "#{device_id}:#{raw_token}"
        return [ nil, "Invalid biometrics credentials" ] unless user.trust_token == expected

        [ user, nil ]
      end

      def self.revoke_trust_token(user)
        user.update!(
          trust_token:            nil,
          trust_token_expires_at: nil,
          biometrics_enabled:     false
        )
      end
    end
  end
end
