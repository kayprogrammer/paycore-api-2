module Common
  module Utils
    class JwtService
      ALGORITHM = "HS256"

      def self.config
        Rails.configuration.x.app
      end

      # ------ Access token (short-lived) --------------------------------- #

      def self.encode(payload)
        expiry = config.jwt_expiry_hours.to_i.hours.from_now
        JWT.encode(
          payload.merge(exp: expiry.to_i, token_type: "access"),
          config.jwt_secret, ALGORITHM
        )
      end

      def self.decode(token)
        decoded = JWT.decode(token, config.jwt_secret, true, { algorithm: ALGORITHM })
        HashWithIndifferentAccess.new(decoded.first)
      end

      # ------ Refresh token (long-lived: 30 days) ------------------------ #

      def self.encode_refresh(payload)
        expiry = 30.days.from_now
        JWT.encode(
          payload.merge(exp: expiry.to_i, token_type: "refresh"),
          config.jwt_secret, ALGORITHM
        )
      end

      def self.decode_refresh(token)
        decoded = JWT.decode(token, config.jwt_secret, true, { algorithm: ALGORITHM })
        payload = HashWithIndifferentAccess.new(decoded.first)
        raise JWT::DecodeError, "Not a refresh token" unless payload[:token_type] == "refresh"
        payload
      end
    end
  end
end
