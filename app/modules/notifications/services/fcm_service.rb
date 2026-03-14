module Notifications
  module Services
    # Sends Firebase Cloud Messaging push notifications via the HTTP v1 API.
    # Uses Google OAuth2 service-account credentials stored in APP_FIREBASE_CREDENTIALS_JSON.
    class FcmService
      FCM_ENDPOINT = "https://fcm.googleapis.com/v1/projects/%s/messages:send"

      # Sends a push notification to all registered devices of a user.
      def self.notify(user:, title:, body:, data: {})
        devices = Notifications::Models::Device.where(user: user)
        return if devices.none?

        access_token = fetch_access_token
        return unless access_token

        project_id = firebase_project_id
        url        = FCM_ENDPOINT % project_id

        devices.each do |device|
          send_to_device(url, access_token, device.token, title, body, data)
        end
      end

      # Registers a device token for a user (called after login with a device_token param).
      def self.register_device(user:, token:, device_type:, device_id: nil)
        Notifications::Models::Device.register(
          user: user, token: token, device_type: device_type, device_id: device_id
        )
      end

      private

      def self.send_to_device(url, access_token, token, title, body, data)
        payload = {
          message: {
            token:        token,
            notification: { title: title, body: body },
            data:         data.transform_values(&:to_s)
          }
        }

        conn = Faraday.new(url: url) do |f|
          f.request  :json
          f.response :json
          f.adapter  Faraday.default_adapter
        end

        response = conn.post do |req|
          req.headers["Authorization"] = "Bearer #{access_token}"
          req.headers["Content-Type"]  = "application/json"
          req.body = payload
        end

        unless response.success?
          Rails.logger.warn("[FCM] Failed to send to #{token}: #{response.body}")
        end
      rescue StandardError => e
        Rails.logger.error("[FCM] Error: #{e.message}")
      end

      # Fetches a short-lived OAuth2 access token using the service account credentials.
      def self.fetch_access_token
        credentials_json = ENV.fetch("APP_FIREBASE_CREDENTIALS_JSON", nil)
        return nil if credentials_json.blank?

        require "googleauth"
        credentials = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: StringIO.new(credentials_json),
          scope:       "https://www.googleapis.com/auth/firebase.messaging"
        )
        credentials.fetch_access_token!["access_token"]
      rescue StandardError => e
        Rails.logger.error("[FCM] Failed to get access token: #{e.message}")
        nil
      end

      def self.firebase_project_id
        ENV.fetch("APP_FIREBASE_PROJECT_ID", "")
      end
    end
  end
end
