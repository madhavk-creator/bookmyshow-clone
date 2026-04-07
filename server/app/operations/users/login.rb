module Users
  class Login < ::Trailblazer::Operation
    step :find_user
    step :verify_password
    step :validate_active
    step :validate_role
    step :build_response
    fail :collect_error

    def find_user(ctx, params:, **)
      email = params[:email]&.to_s&.downcase&.strip
      ctx[:model] = ::User.find_by(email: email)
      true
    end

    def verify_password(ctx, model:, params:, **)
      return true if model&.valid_password?(params[:password])

      ctx[:error] = "Invalid email or password"
      ctx[:status] = :unauthorized
      false
    end

    def validate_active(ctx, model:, **)
      return true if model.is_active?

      ctx[:error] = "Account is deactivated. Contact support."
      ctx[:status] = :unauthorized
      false
    end

    def validate_role(ctx, model:, expected_role:, **)
      return true if model.role == expected_role.to_s

      ctx[:error] = "Invalid email or password"
      ctx[:status] = :unauthorized
      false
    end

    def build_response(ctx, model:, **)
      ctx[:response_data] = {
        token: JsonWebToken.encode({ user_id: model.id }),
        user: Users::Serializer.call(model)
      }
    end

    def collect_error(ctx, **)
      ctx[:error] ||= "Invalid email or password"
      ctx[:status] ||= :unprocessable_entity
    end
  end
end
