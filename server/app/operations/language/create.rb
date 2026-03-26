class Language
  class Create < Trailblazer::Operation
    step :build
    step :persist
    fail :collect_errors

    private

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
      ctx[:errors] = model.errors.to_hash(true)
    end
  end

  class Update < Trailblazer::Operation
    step :find
    step :assign
    step :persist
    fail :collect_errors

    private

    def find(ctx, params:, **)
      ctx[:model] = ::Language.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['Language not found'] }
        return false
      end
    end

    def assign(ctx, params:, model:, **)
      model.name = params[:name].strip.titleize if params[:name].present?
      model.code = params[:code].strip.downcase if params[:code].present?
    end

    def persist(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, model:, **)
      ctx[:errors] ||= model.errors.to_hash(true)
    end
  end

  class Destroy < Trailblazer::Operation
    step :find
    step :destroy
    fail :collect_errors

    private

    def find(ctx, params:, **)
      ctx[:model] = ::Language.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['Language not found'] }
        return false
      end
    end

    def destroy(ctx, model:, **)
      model.destroy
    rescue ActiveRecord::DeleteRestrictionError
      ctx[:errors] = { base: ['Cannot delete a language that is in use by movies'] }
      false
    end

    def collect_errors(ctx, model:, **)
      ctx[:errors] ||= { base: ['Could not delete language'] }
    end
  end
end