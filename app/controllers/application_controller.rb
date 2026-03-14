class ApplicationController < ActionController::API
  include Common::Utils::ResponseHelper

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from JWT::DecodeError, with: :invalid_token
  rescue_from JWT::ExpiredSignature, with: :token_expired
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  private

  def authenticate_user!
    header = request.headers["Authorization"]
    token  = header&.split(" ")&.last
    payload = Common::Utils::JwtService.decode(token)
    user = Accounts::Models::User.active.find_by(id: payload[:user_id])

    # Check the token is still the one we have on record (revocation check)
    unless user && user.access == token
      return render_error(message: "Unauthorized", status: :unauthorized)
    end

    @current_user = user
  rescue JWT::DecodeError, JWT::ExpiredSignature
    render_error(message: "Unauthorized", status: :unauthorized)
  end

  def current_user
    @current_user
  end

  def record_not_found(error)
    render_error(message: error.message, status: :not_found)
  end

  def record_invalid(error)
    render_error(message: "Validation failed", errors: error.record.errors.full_messages, status: :unprocessable_entity)
  end

  def invalid_token(_error)
    render_error(message: "Invalid or missing token", status: :unauthorized)
  end

  def token_expired(_error)
    render_error(message: "Token has expired", status: :unauthorized)
  end

  def parameter_missing(error)
    render_error(message: error.message, status: :bad_request)
  end
end
