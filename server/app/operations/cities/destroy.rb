module Cities
  class Destroy < ::Trailblazer::Operation
    step :find_city
    step :destroy
    fail :collect_errors

    def find_city(ctx, params:, **)
      ctx[:model] = ::City.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: [ "City not found" ] }
        return false
      end
    true
    end

    def destroy(ctx, model:, **)
      model.destroy
    rescue ActiveRecord::DeleteRestrictionError
      ctx[:errors] = { base: [ "Cannot delete a city that has theatres" ] }
      false
    end

    def collect_errors(ctx, model:, **)
      ctx[:errors] ||= { base: [ "Could not delete city" ] }
    end
  end
end
