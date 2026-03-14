class AddFullFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    # Rename name -> first_name, add last_name
    rename_column :users, :name, :first_name
    add_column    :users, :last_name,  :string, null: false, default: ""

    # Contact & identity
    add_column :users, :phone,         :string,  limit: 20
    add_column :users, :bio,           :string,  limit: 200
    add_column :users, :dob,           :date

    # Avatar (Cloudinary public_id or URL)
    add_column :users, :avatar,        :string
    add_column :users, :social_avatar, :string,  limit: 1000

    # Flags
    add_column :users, :is_staff,             :boolean, default: false, null: false
    add_column :users, :is_active,            :boolean, default: true,  null: false
    add_column :users, :biometrics_enabled,   :boolean, default: false, null: false

    # OTP
    add_column :users, :otp_code,       :integer
    add_column :users, :otp_expires_at, :datetime

    # Trust token (for device-trust / remember-me flows)
    add_column :users, :trust_token,            :text
    add_column :users, :trust_token_expires_at, :datetime

    # Stored JWT tokens (for server-side revocation)
    add_column :users, :access,  :text
    add_column :users, :refresh, :text

    # Notification preferences
    add_column :users, :push_enabled,   :boolean, default: true, null: false
    add_column :users, :in_app_enabled, :boolean, default: true, null: false
    add_column :users, :email_enabled,  :boolean, default: true, null: false

    # Indexes
    add_index :users, :phone, unique: true
  end
end
