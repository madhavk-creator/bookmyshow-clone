module Cities
  class Create < ::Trailblazer::Operation
    step :authorize_create
    step :build_city
    step :persist
    fail :collect_errors

    def authorize_create(ctx, current_user:, **)
      return true if Pundit.policy!(current_user, ::City).create?

      ctx[:errors] = { base: [ "Not authorized to create city" ] }
      false
    end

    def build_city(ctx, params:, **)
      ctx[:model] = ::City.new(
        name:  params[:name]&.strip&.titleize,
        state: params[:state]&.strip&.titleize
      )
    end

    def persist(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end
