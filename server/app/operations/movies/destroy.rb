class Movie
  class Destroy < Trailblazer::Operation
    step :find_movie
    step :destroy
    fail :collect_errors

    private

    def find_movie(ctx, params:, **)
      ctx[:model] = ::Movie.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['Movie not found'] }
        return false
      end
    true
    end

    def destroy(ctx, model:, **)
      model.destroy
    rescue ActiveRecord::DeleteRestrictionError
      ctx[:errors] = { base: ['Cannot delete a movie that has scheduled shows'] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= { base: ['Could not delete movie'] }
    end
  end
end