module Cities
  class Create < Trailblazer::Operation
    step :build_city
    step :persist
    fail :collect_errors

    def build_city(ctx, params:, **)
      ctx[:model] = ::City.new(
        name:  params[:name]&.strip&.titleize,
        state: params[:state]&.strip&.titleize
      )
    end

    def persist(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, model:, **)
      ctx[:errors] = model.errors.to_hash(true)
    end
  end
end