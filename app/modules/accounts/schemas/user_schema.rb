module Accounts
  module Schemas
    class UserSchema
      def self.call(user)
        {
          id:                      user.id,
          first_name:              user.first_name,
          last_name:               user.last_name,
          full_name:               user.full_name,
          email:                   user.email,
          phone:                   user.phone,
          avatar_url:              user.avatar_url,
          bio:                     user.bio,
          dob:                     user.dob,
          is_email_verified:       user.is_email_verified,
          is_staff:                user.is_staff,
          is_active:               user.is_active,
          biometrics_enabled:      user.biometrics_enabled,
          push_enabled:            user.push_enabled,
          in_app_enabled:          user.in_app_enabled,
          email_enabled:           user.email_enabled,
          created_at:              user.created_at
        }
      end
    end
  end
end
