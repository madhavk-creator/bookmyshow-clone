class Format
  class Update < Trailblazer::Operation
    step :update_attributes
    step :persist
    fail :collect_errors

    private

    def update_attributes(ctx, params:, model:, **)
      allowed = %i[name code]
      model.assign_attributes(params.slice(*allowed).compact)
      true
    end

    def persist(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, **)
      ctx[:errors] ||= {}
      ctx[:errors].merge!(ctx[:model].errors.to_hash(true)) if ctx[:model]
    end
  end
end
