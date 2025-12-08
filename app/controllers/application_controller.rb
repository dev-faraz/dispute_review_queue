class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action { Current.user = current_user }

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized


  allow_browser versions: :modern

  stale_when_importmap_changes

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
