module Accounts
  module Schemas
    class UserSchema
      def self.call(user)
        {
          id: user.id,
          name: user.name,
          email: user.email,
          is_email_verified: user.is_email_verified,
          created_at: user.created_at
        }
      end
    end
  end
end
