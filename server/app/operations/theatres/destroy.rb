module Theatres
  class Destroy < ::Trailblazer::Operation
    step :find_theatre
    step :destroy
    fail :collect_errors

    def find_theatre(ctx, params:, **)
      ctx[:model] = Theatre.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: [ "Theatre not found" ] }
        return false
      end
      true
    end

    def destroy(ctx, model:, **)
      model.destroy
    rescue ActiveRecord::DeleteRestrictionError
      ctx[:errors] = { base: [ "Cannot delete theatres with existing screens" ] }
      false
    end

    def collect_errors(ctx, **)
      ctx[:errors] ||= ctx[:model].errors.to_hash(true)
    end
  end
end
