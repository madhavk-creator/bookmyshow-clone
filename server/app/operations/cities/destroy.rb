module Cities
  class Destroy < ::Trailblazer::Operation
    step :find_city
    step :authorize_city
    step :destroy
    fail :collect_errors

    def find_city(ctx, params:, model: nil, **)
      return true if model.present?

      ctx[:model] = ::City.find_by(id: params[:id])
      return true if ctx[:model]

      ctx[:errors] = { base: [ "City not found" ] }
      false
    end

    def authorize_city(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).destroy?

      ctx[:errors] = { base: [ "Not authorized to delete this city" ] }
      false
    end

    def destroy(ctx, model:, **)
      model.destroy
    rescue ActiveRecord::DeleteRestrictionError
      ctx[:errors] = { base: [ "Cannot delete a city that has theatres" ] }
      false
    end

    def collect_errors(ctx, model:, **)
      ctx[:errors] ||= model.errors.to_hash(true).presence || { base: [ "Could not delete city" ] }
    end
  end
end
