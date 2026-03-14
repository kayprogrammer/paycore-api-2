class AccountsMailer < ApplicationMailer
  default from: ENV.fetch("APP_MAIL_FROM", "PayCore <noreply@paycore.app>")

  # Sends a 6-digit OTP for email verification, login MFA, or password reset.
  # purpose: "account verification" | "login verification" | "password reset"
  def otp_email(user, purpose)
    @user    = user
    @purpose = purpose
    @otp     = user.otp_code

    subject = case purpose
    when "account verification" then "Verify your PayCore email"
    when "login verification"   then "Your PayCore login OTP"
    when "password reset"       then "Reset your PayCore password"
    else "Your PayCore OTP code"
    end

    mail(to: user.email, subject: subject)
  end

  # Sent after initial email verification succeeds.
  def welcome_email(user)
    @user = user
    mail(to: user.email, subject: "Welcome to PayCore, #{user.first_name}!")
  end

  # Sent after a successful password reset.
  def password_reset_confirmation(user)
    @user = user
    mail(to: user.email, subject: "Your PayCore password has been changed")
  end
end
