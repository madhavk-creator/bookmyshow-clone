module Authenticatable
  extend ActiveSupport::Concern

  included do
    attr_reader :current_user
  end

  # Validates the JWT in the Authorization header and sets current_user.
  # Renders 401 and halts the action if anything fails.
  def authenticate!
    payload = decode_token!
    return unless payload   # decode_token! already rendered on failure

    user = User.find_by(id: payload[:user_id])
    unless user&.is_active?
      render json: { error: 'Unauthorized' }, status: :unauthorized and return
    end

    @current_user = user
  end

  # Authenticate and enforce a specific role.
  # Renders 403 if the user is authenticated but has the wrong role.
  def require_role!(*roles)
    authenticate!
    return unless current_user

    unless roles.map(&:to_s).include?(current_user.role)
      render json: { error: 'Forbidden' }, status: :forbidden
    end
  end

  private

  def decode_token!
    header = request.headers['Authorization']
    unless header&.start_with?('Bearer ')
      render json: { error: 'Missing or malformed Authorization header' },
             status: :unauthorized
      return nil
    end

    token = header.split(' ', 2).last
    JsonWebToken.decode(token)
  rescue JsonWebToken::Error => e
    render json: { error: e.message }, status: :unauthorized
    nil
  end
end