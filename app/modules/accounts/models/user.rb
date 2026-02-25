module Accounts
  module Models
    class User < ApplicationRecord
      self.table_name = "users"

      include Common::Concerns::SoftDeletable

      has_secure_password

      validates :email, presence: true, uniqueness: { case_sensitive: false },
                        format: { with: URI::MailTo::EMAIL_REGEXP }
      validates :name, presence: true

      before_save { self.email = email.downcase }
    end
  end
end
