module Languages
  class Destroy < ::Trailblazer::Operation
    step :find_language
    step :authorize_language
    step :validate_not_in_use
    step :destroy
    fail :collect_errors

    def find_language(ctx, params:, model: nil, **)
      return true if model.present?

      ctx[:model] = ::Language.find_by(id: params[:id])
      return true if ctx[:model]

      ctx[:errors] = { base: [ "Language not found" ] }
      false
    end

    def authorize_language(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).destroy?

      ctx[:errors] = { base: [ "Not authorized to delete this language" ] }
      false
    end

    def validate_not_in_use(ctx, model:, **)
      if model.movie_languages.joins(:shows).where(shows: { status: "scheduled" }).exists?
        ctx[:errors] = { base: [ "Cannot delete a language that still has scheduled shows" ] }
        return false
      end

      if model.movie_languages.exists?
        ctx[:errors] = { base: [ "Cannot delete a language that is still used by movies" ] }
        return false
      end

      true
    end

    def destroy(ctx, model:, **)
      model.destroy
    end

    def collect_errors(ctx, model:, **)
      ctx[:errors] ||= model.errors.to_hash(true).presence || { base: [ "Could not delete language" ] }
    end
  end
end
