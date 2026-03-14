module Accounts
  class SendOtpEmailJob < ApplicationJob
    queue_as :emails

    # purpose: "account verification" | "login verification" | "password reset"
    def perform(user_id, purpose)
      user = Accounts::Models::User.find(user_id)
      user.generate_otp!
      AccountsMailer.otp_email(user, purpose).deliver_now
    end
  end
end
