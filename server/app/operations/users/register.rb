module Users
  class Register < ::Trailblazer::Operation
    step :validate_params
    step :build_user
    step :assign_role
    step :persist
    fail :collect_errors

    def validate_params(ctx, params:, **)
      required = %i[name email password password_confirmation]
      missing  = required.select { |key| value_for(params, key).blank? }

      if missing.any?
        ctx[:errors] = { base: [ "Missing required fields: #{missing.join(', ')}" ] }
        return false
      end

      if value_for(params, :password) != value_for(params, :password_confirmation)
        ctx[:errors] = { password_confirmation: [ "doesn't match Password" ] }
        return false
      end

      true
    end

    def build_user(ctx, params:, **)
      ctx[:model] = ::User.new(
        name:                  params[:name],
        email:                 params[:email],
        password:              params[:password],
        password_confirmation: params[:password_confirmation],
        phone:                 params[:phone]
      )
    end

    def assign_role(ctx, model:, **)
      model.role = :user
    end

    def persist(ctx, model:, **)
      model.save   # false triggers fail track
    end

    def collect_errors(ctx, **)
      ctx[:errors] = ctx[:model]&.errors&.to_hash(true) || { base: [ "User could not be created" ] }
    end

    private

    def value_for(params, key)
      params[key] || params[key.to_s]
    end
  end
end
