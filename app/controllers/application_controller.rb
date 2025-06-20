class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :ensure_user_account_matches_tenant, if: :user_signed_in?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :role ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :role ])
  end

  def ensure_user_account_matches_tenant
    if Current.account && current_user.account != Current.account
      sign_out current_user
      redirect_to new_user_session_path, alert: "Access denied for this account"
    end
  end

  def current_account
    Current.account || current_user&.account
  end
  helper_method :current_account
end
