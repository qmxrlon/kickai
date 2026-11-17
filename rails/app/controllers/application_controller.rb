class ApplicationController < ActionController::Base
  include Pagy::Backend

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def require_premium!
    unless current_user&.can_view_predictions?
      flash[:alert] = "Diese Funktion ist nur für Premium-Abonnenten verfügbar."
      redirect_to pricing_path
    end
  end

  def require_admin!
    redirect_to root_path, alert: "Zugriff verweigert." unless current_user&.admin?
  end
end
