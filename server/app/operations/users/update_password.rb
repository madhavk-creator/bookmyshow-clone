module Users
  class UpdatePassword < ::Trailblazer::Operation
    step :find_user
    step :validate_expected_role
    step :authorize_update
    step :validate_current_password_presence
    step :validate_current_password
    step :update_password
    step :build_response
    fail :collect_errors

    def find_user(ctx, current_user:, **)
      ctx[:model] = current_user
      return true if ctx[:model].present?

      ctx[:errors] = { base: [ "Not authorized to update password" ] }
      ctx[:status] = :forbidden
      false
    end

    def validate_expected_role(ctx, model:, expected_role:, **)
      return true if model.role == expected_role.to_s

      ctx[:errors] = { base: [ "Not authorized to update password" ] }
      ctx[:status] = :forbidden
      false
    end

    def authorize_update(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).update?

      ctx[:errors] = { base: [ "Not authorized to update password" ] }
      ctx[:status] = :forbidden
      false
    end

    def validate_current_password_presence(ctx, params:, **)
      return true if params[:current_password].present?

      ctx[:errors] = { current_password: [ "can't be blank" ] }
      ctx[:status] = :unprocessable_entity
      false
    end

    def validate_current_password(ctx, model:, params:, **)
      return true if model.valid_password?(params[:current_password])

      ctx[:errors] = { current_password: [ "is incorrect" ] }
      ctx[:status] = :unprocessable_entity
      false
    end

    def update_password(ctx, model:, params:, **)
      updates = params.slice(:password, :password_confirmation)
      return true if model.update(updates)

      ctx[:errors] = model.errors.to_hash(true)
      ctx[:status] = :unprocessable_entity
      false
    end

    def build_response(ctx, model:, **)
      ctx[:response_data] = {
        token: JsonWebToken.encode({ user_id: model.id }),
        user: Users::Serializer.call(model)
      }
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || { base: [ "Could not update password" ] }
      ctx[:status] ||= :unprocessable_entity
    end
  end
end
