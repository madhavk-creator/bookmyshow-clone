class City
  class Create < Trailblazer::Operation
    step :build_city
    step :persist
    fail :collect_errors

    private

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

  class Destroy < Trailblazer::Operation
    step :find_city
    step :destroy
    fail :collect_errors

    private

    def find_city(ctx, params:, **)
      ctx[:model] = ::City.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['City not found'] }
        return false
      end
    end

    def destroy(ctx, model:, **)
      model.destroy
    rescue ActiveRecord::DeleteRestrictionError
      ctx[:errors] = { base: ['Cannot delete a city that has theatres'] }
      false
    end

    def collect_errors(ctx, model:, **)
      ctx[:errors] ||= { base: ['Could not delete city'] }
    end
  end
end