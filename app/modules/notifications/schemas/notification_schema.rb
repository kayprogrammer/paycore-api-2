module Notifications
  module Schemas
    class NotificationSchema
      def self.call(notification)
        {
          id:         notification.id,
          ntype:      notification.ntype,
          title:      notification.title,
          body:       notification.body,
          is_read:    notification.is_read,
          metadata:   notification.metadata,
          created_at: notification.created_at
        }
      end

      def self.collection(notifications)
        notifications.map { |n| call(n) }
      end
    end
  end
end
