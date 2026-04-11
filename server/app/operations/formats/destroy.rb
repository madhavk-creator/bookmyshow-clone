module Formats
  class Destroy < ::Trailblazer::Operation
    step :find_format
    step :authorize_format
    step :validate_not_in_use
    step :destroy
    fail :collect_errors

    def find_format(ctx, params:, model: nil, **)
      return true if model.present?

      ctx[:model] = ::Format.find_by(id: params[:id])
      return true if ctx[:model]

      ctx[:errors] = { base: [ "Format not found" ] }
      false
    end

    def authorize_format(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).destroy?

      ctx[:errors] = { base: [ "Not authorized to delete this format" ] }
      false
    end

    def validate_not_in_use(ctx, model:, **)
      if model.screen_capabilities.exists?
        ctx[:errors] = { base: [ "Cannot delete a format that is still enabled on screens" ] }
        return false
      end

      if model.movie_formats.joins(:shows).where(shows: { status: "scheduled" }).exists?
        ctx[:errors] = { base: [ "Cannot delete a format that still has scheduled shows" ] }
        return false
      end

      if model.movie_formats.exists?
        ctx[:errors] = { base: [ "Cannot delete a format that is still used by movies" ] }
        return false
      end

      true
    end

    def destroy(ctx, model:, **)
      model.destroy
    end

    def collect_errors(ctx, model:, **)
      ctx[:errors] ||= model.errors.to_hash(true).presence || { base: [ "Could not delete format" ] }
    end
  end
end
