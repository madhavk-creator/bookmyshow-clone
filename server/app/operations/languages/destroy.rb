module Languages
  class Destroy < ::Trailblazer::Operation
    step :find_language
    step :authorize_language
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

    def destroy(ctx, model:, **)
      model.destroy
    rescue ActiveRecord::DeleteRestrictionError
      ctx[:errors] = { base: [ "Cannot delete a language that is in use by movies" ] }
      false
    end

    def collect_errors(ctx, model:, **)
      ctx[:errors] ||= model.errors.to_hash(true).presence || { base: [ "Could not delete language" ] }
    end
  end
end
