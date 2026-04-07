module Languages
  class Create < ::Trailblazer::Operation
    step :authorize_create
    step :build
    step :persist
    fail :collect_errors

    def authorize_create(ctx, current_user:, **)
      return true if Pundit.policy!(current_user, ::Language).create?

      ctx[:errors] = { base: [ "Not authorized to create language" ] }
      false
    end

    def build(ctx, params:, **)
      ctx[:model] = ::Language.new(
        name: params[:name]&.strip&.titleize,
        code: params[:code]&.strip&.downcase
      )
    end

    def persist(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end
