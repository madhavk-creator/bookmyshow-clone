class Screen
  class Destroy < Trailblazer::Operation
    step :find_screen
    step :destroy
    fail :collect_errors

    private

    def find_screen(ctx, params:, **)
      ctx[:model] = ::Screen.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['Screen not found'] }
        return false
      end
    end

    def destroy(ctx, model:, **)
      model.destroy
    rescue ActiveRecord::DeleteRestrictionError
      ctx[:errors] = { base: ['Cannot delete a screen that has seats or shows'] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= { base: ['Could not delete screen'] }
    end
  end
end