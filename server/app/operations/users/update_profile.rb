module Users
  class UpdateProfile < ::Trailblazer::Operation
    step :find_user
    step :validate_expected_role
    step :authorize_update
    step :update_profile
    step :build_response
    fail :collect_errors

    def find_user(ctx, current_user:, **)
      ctx[:model] = current_user
      return true if ctx[:model].present?

      ctx[:errors] = { base: [ "Not authorized to update this profile" ] }
      ctx[:status] = :forbidden
      false
    end

    def validate_expected_role(ctx, model:, expected_role:, **)
      return true if model.role == expected_role.to_s

      ctx[:errors] = { base: [ "Not authorized to update this profile" ] }
      ctx[:status] = :forbidden
      false
    end

    def authorize_update(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).update?

      ctx[:errors] = { base: [ "Not authorized to update this profile" ] }
      ctx[:status] = :forbidden
      false
    end

    def update_profile(ctx, model:, params:, **)
      attributes = params.slice(:name, :email, :phone).compact
      return true if model.update(attributes)

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
      ctx[:errors] ||= model&.errors&.to_hash(true) || { base: [ "Could not update profile" ] }
      ctx[:status] ||= :unprocessable_entity
    end
  end
end
