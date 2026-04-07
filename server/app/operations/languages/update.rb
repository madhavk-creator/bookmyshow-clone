module Languages
  class Update < ::Trailblazer::Operation
    step :find_language
    step :authorize_language
    step :assign
    step :persist
    fail :collect_errors

    def find_language(ctx, params:, model: nil, **)
      return true if model.present?

      ctx[:model] = ::Language.find_by(id: params[:id])
      return true if ctx[:model]

      ctx[:errors] = { base: [ "Language not found" ] }
      false
    end

    def authorize_language(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).update?

      ctx[:errors] = { base: [ "Not authorized to update this language" ] }
      false
    end

    def assign(ctx, params:, model:, **)
      model.name = params[:name].strip.titleize if params[:name].present?
      model.code = params[:code].strip.downcase if params[:code].present?
      true
    end

    def persist(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, model:, **)
      ctx[:errors] ||= model.errors.to_hash(true)
    end
  end
end
