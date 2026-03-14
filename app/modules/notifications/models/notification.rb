module Notifications
  module Models
    class Notification < ApplicationRecord
      self.table_name = "notifications"

      belongs_to :user, class_name: "Accounts::Models::User"

      validates :ntype, :title, :body, presence: true

      scope :unread,   -> { where(is_read: false) }
      scope :for_user, ->(user) { where(user: user).order(created_at: :desc) }

      # Convenience factory — creates and returns a notification.
      def self.notify(user:, ntype:, title:, body:, metadata: {})
        create!(user: user, ntype: ntype, title: title, body: body, metadata: metadata)
      end
    end
  end
end
