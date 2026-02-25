module Common
  module Utils
    class JwtService
      ALGORITHM = "HS256"

      def self.config
        Rails.configuration.x.app
      end

      def self.encode(payload)
        expiry = config.jwt_expiry_hours.to_i.hours.from_now
        JWT.encode(payload.merge(exp: expiry.to_i), config.jwt_secret, ALGORITHM)
      end

      def self.decode(token)
        decoded = JWT.decode(token, config.jwt_secret, true, { algorithm: ALGORITHM })
        HashWithIndifferentAccess.new(decoded.first)
      end
    end
  end
end
