module Cities
  class Destroy < ::Trailblazer::Operation
    step :find_city
    step :authorize_city
    step :validate_not_in_use
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

    def validate_not_in_use(ctx, model:, **)
      return true unless model.theatres.exists?

      ctx[:errors] = { base: [ "Cannot delete a city that still has theatres" ] }
      false
    end

    def destroy(ctx, model:, **)
      model.destroy
    end

    def collect_errors(ctx, model:, **)
      ctx[:errors] ||= model.errors.to_hash(true).presence || { base: [ "Could not delete city" ] }
    end
  end
end
