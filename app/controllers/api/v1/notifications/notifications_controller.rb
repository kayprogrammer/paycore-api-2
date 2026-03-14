module Api
  module V1
    module Notifications
      class NotificationsController < ApplicationController
        before_action :authenticate_user!
        include Pagy::Backend

        # GET /api/v1/notifications/
        # Returns paginated list of the current user's notifications (newest first).
        def index
          notifications = ::Notifications::Models::Notification
                            .for_user(current_user)
                            .includes(:user)

          pagy, paginated = pagy(notifications, limit: 20)

          render_success(
            data: {
              notifications: ::Notifications::Schemas::NotificationSchema.collection(paginated),
              unread_count:  notifications.unread.count,
              pagination: {
                count:    pagy.count,
                page:     pagy.page,
                pages:    pagy.pages,
                per_page: pagy.limit
              }
            }
          )
        end

        # PATCH /api/v1/notifications/:id/read
        # Marks a single notification as read.
        def mark_read
          notification = ::Notifications::Models::Notification
                           .for_user(current_user)
                           .find(params[:id])

          notification.update!(is_read: true)
          render_success(
            data: { notification: ::Notifications::Schemas::NotificationSchema.call(notification) },
            message: "Notification marked as read"
          )
        end

        # PATCH /api/v1/notifications/read-all
        # Marks all of the current user's unread notifications as read.
        def mark_all_read
          ::Notifications::Models::Notification
            .for_user(current_user)
            .unread
            .update_all(is_read: true)

          render_success(message: "All notifications marked as read")
        end
      end
    end
  end
end
