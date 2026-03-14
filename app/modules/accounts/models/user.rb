module Accounts
  module Models
    class User < ApplicationRecord
      self.table_name = "users"

      include Common::Concerns::SoftDeletable

      has_secure_password

      # Validations
      validates :email, presence: true,
                        uniqueness: { case_sensitive: false },
                        format: { with: URI::MailTo::EMAIL_REGEXP }
      validates :first_name, :last_name, presence: true
      validates :phone, uniqueness: true, allow_nil: true

      before_save { self.email = email.downcase }

      # ------------------------------------------------------------------ #
      # Computed attributes                                                  #
      # ------------------------------------------------------------------ #

      def full_name
        "#{first_name} #{last_name}"
      end

      def avatar_url
        avatar.presence || social_avatar
      end

      # ------------------------------------------------------------------ #
      # OTP helpers                                                          #
      # ------------------------------------------------------------------ #

      def otp_expired?
        return true if otp_expires_at.nil?
        Time.current > otp_expires_at
      end

      def generate_otp!
        update!(
          otp_code:       SecureRandom.random_number(100_000..999_999),
          otp_expires_at: 10.minutes.from_now
        )
        otp_code
      end

      def clear_otp!
        update!(otp_code: nil, otp_expires_at: nil)
      end

      # ------------------------------------------------------------------ #
      # Trust token helpers                                                  #
      # ------------------------------------------------------------------ #

      def trust_token_expired?
        trust_token_expires_at.present? && Time.current > trust_token_expires_at
      end
    end
  end
end
