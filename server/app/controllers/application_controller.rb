class ApplicationController < ActionController::API
  include Authenticatable
  include Pundit::Authorization

  private

  # return the result object and yield only on successful operations.
  def run(operation, **options)
    call_options = options.key?(:current_user) ? options : options.merge(current_user: current_user)
    result = operation.call(**call_options)
    yield(result) if result.success? && block_given?
    result
  end

  # Pundit: rescue policy violations globally
  rescue_from Pundit::NotAuthorizedError do
    render json: { error: "Forbidden" }, status: :forbidden
  end

  # Pundit: tell it who the current users is
  # (Pundit looks for current_user automatically via this method name)
end
