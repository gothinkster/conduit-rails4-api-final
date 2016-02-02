class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session
  # skip_before_filter :verify_authenticity_token
  before_action :configure_permitted_parameters, if: :devise_controller?

  respond_to :json

  private

  def authenticate_user!(options = {})
    authenticate_or_request_with_http_token do |token|
      begin
        jwt_payload = JWT.decode(token, Rails.application.secrets.jwt_secret).first

        @current_user = User.find(jwt_payload['id'])
      rescue JWT::ExpiredSignature, JWT::VerificationError, JWT::DecodeError
        head :unauthorized
      end
    end
  end

  # def current_user
  #   @current_user || current_user
  # end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :username
  end
end
