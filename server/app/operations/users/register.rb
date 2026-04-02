module Users
  class Register < Trailblazer::Operation
    step :validate_params
    step :build_user
    step :assign_role
    step :persist
    fail :collect_errors

    private

    def validate_params(ctx, params:, **)
      required = %w[name email password password_confirmation]
      missing  = required.select { |k| params[k].blank? }

      if missing.any?
        ctx[:errors] = { base: ["Missing required fields: #{missing.join(', ')}"] }
        return false
      end

      if params[:password] != params[:password_confirmation]
        ctx[:errors] = { password_confirmation: ["doesn't match Password"] }
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
      ctx[:errors] = ctx[:model].errors.to_hash(true)
    end
  end
end