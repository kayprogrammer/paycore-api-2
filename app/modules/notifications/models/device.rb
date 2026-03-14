module Notifications
  module Models
    class Device < ApplicationRecord
      self.table_name = "devices"

      belongs_to :user, class_name: "Accounts::Models::User"

      validates :token, :device_type, presence: true
      validates :token, uniqueness: true
      validates :device_type, inclusion: { in: %w[ios android web] }

      # Registers or updates a device token for a user.
      # If the token already exists for another device_type, updates it.
      def self.register(user:, token:, device_type:, device_id: nil)
        find_or_initialize_by(token: token).tap do |device|
          device.user        = user
          device.device_type = device_type
          device.device_id   = device_id
          device.save!
        end
      end
    end
  end
end
