class ApplicationController < ActionController::API
  include Authenticatable
  include Pundit::Authorization

  # Pundit: rescue policy violations globally
  rescue_from Pundit::NotAuthorizedError do
    render json: { error: 'Forbidden' }, status: :forbidden
  end

  # Pundit: tell it who the current user is
  # (Pundit looks for current_user automatically via this method name)
end