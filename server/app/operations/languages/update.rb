module Languages
  class Update < Trailblazer::Operation
    step :assign
    step :persist
    fail :collect_errors

    private

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
