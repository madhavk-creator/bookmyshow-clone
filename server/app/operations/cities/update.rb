class City
  class Update < Trailblazer::Operation
    step :find_city
    step :update_attributes
    step :persist
    fail :collect_errors

    private

    def find_city(ctx, params:, **)
      ctx[:model] = ::City.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['City not found'] }
        return false
      end
    true
    end

    def update_attributes(ctx, params:, model:, **)
      model.assign_attributes(
        name:  params[:name]&.strip&.titleize,
        state: params[:state]&.strip&.titleize
      )
    end

    def persist(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, model:, **)
      ctx[:errors] ||= model.errors.to_hash(true)
    end
  end
end