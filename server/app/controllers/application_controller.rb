class ApplicationController < ActionController::API
  include Authenticatable
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError do
    render json: { error: "Forbidden" }, status: :forbidden
  end

  private

  # Runs an operation with the current_user injected by default.
  # Yields only when the operation succeeds.
  def run(operation, **options)
    call_options = options.key?(:current_user) ? options : options.merge(current_user: current_user)
    result = operation.call(**call_options)
    yield(result) if result.success? && block_given?
    result
  end

  def render_operation_errors(result)
    return if result.success? || performed?

    errors = result[:errors].presence || { base: [ "Request failed" ] }
    render json: { errors: errors }, status: error_status_for(errors)
  end

  def error_status_for(errors)
    messages = errors.values.flatten.map(&:to_s)
    return :not_found if messages.any? { |message| message.downcase.include?("not found") }
    return :forbidden if messages.any? { |message| message.start_with?("Not authorized") || message == "Forbidden" }

    :unprocessable_entity
  end
end
