module Languages
  class Create < ::Trailblazer::Operation
    step :build
    step :persist
    fail :collect_errors

    def build(ctx, params:, **)
      ctx[:model] = ::Language.new(
        name: params[:name]&.strip&.titleize,
        code: params[:code]&.strip&.downcase
      )
    end

    def persist(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, model:, **)
      ctx[:errors] ||= model.errors.to_hash(true)
    end
  end
end
