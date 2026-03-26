class Format
  class Create < Trailblazer::Operation
    step :build
    step :persist
    fail :collect_errors

    private

    def build(ctx, params:, **)
      ctx[:model] = ::Format.new(
        name: params[:name]&.strip&.upcase,
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
      ctx[:model] = ::Format.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['Format not found'] }
        return false
      end
    end

    def assign(ctx, params:, model:, **)
      model.name = params[:name].strip.upcase   if params[:name].present?
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
      ctx[:model] = ::Format.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['Format not found'] }
        return false
      end
    end

    def destroy(ctx, model:, **)
      model.destroy
    rescue ActiveRecord::DeleteRestrictionError
      ctx[:errors] = { base: ['Cannot delete a format that is in use by movies or screens'] }
      false
    end

    def collect_errors(ctx, model:, **)
      ctx[:errors] ||= { base: ['Could not delete format'] }
    end
  end
end