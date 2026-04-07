module Cities
  class Update < ::Trailblazer::Operation
    step :update_attributes
    step :persist
    fail :collect_errors

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
