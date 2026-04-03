module Screens
  class Destroy < Trailblazer::Operation
    step :find_screen
    step :destroy
    fail :collect_errors

    def find_screen(ctx, params:, **)
      ctx[:model] = ::Screen.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['Screen not found'] }
        return false
      end
    true
    end

    def destroy(ctx, model:, **)
      model.destroy
    rescue ActiveRecord::DeleteRestrictionError
      ctx[:errors] = { base: ['Cannot delete a screens that has seats or shows'] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= { base: ['Could not delete screens'] }
    end
  end
end