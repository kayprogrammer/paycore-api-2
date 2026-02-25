module Common
  module Utils
    module ResponseHelper
      def render_success(data: nil, message: "Success", status: :ok)
        render json: { success: true, message: message, data: data }, status: status
      end

      def render_error(message: "An error occurred", errors: nil, status: :bad_request)
        payload = { success: false, message: message }
        payload[:errors] = errors if errors.present?
        render json: payload, status: status
      end
    end
  end
end
