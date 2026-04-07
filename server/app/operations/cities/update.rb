module Cities
  class Update < ::Trailblazer::Operation
    step :find_city
    step :authorize_city
    step :update_attributes
    step :persist
    fail :collect_errors

    def find_city(ctx, params:, model: nil, **)
      return true if model.present?

      ctx[:model] = ::City.find_by(id: params[:id])
      return true if ctx[:model]

      ctx[:errors] = { base: [ "City not found" ] }
      false
    end

    def authorize_city(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).update?

      ctx[:errors] = { base: [ "Not authorized to update this city" ] }
      false
    end

    def update_attributes(ctx, params:, model:, **)
      model.assign_attributes(
        name:  params[:name]&.strip&.titleize,
        state: params[:state]&.strip&.titleize
      )
      true
    end

    def persist(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, model:, **)
      ctx[:errors] ||= model.errors.to_hash(true)
    end
  end
end
