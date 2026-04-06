module Reviews
  class Destroy < ::Trailblazer::Operation
    step :find_review
    step :authorize_review
    step :destroy_review
    fail :collect_errors

    def find_review(ctx, params:, current_user:, **)
      ctx[:model] = ::Review.find_by(id: params[:id], movie_id: params[:movie_id])
      return true if ctx[:model]

      ctx[:errors] = { review: [ "Review not found" ] }
      false
    end

    def authorize_review(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).destroy?

      ctx[:errors] = { base: [ "Not authorized to delete this review" ] }
      false
    end

    def destroy_review(ctx, model:, **)
      return true if model.destroy

      ctx[:errors] = model.errors.to_hash(true).presence || { base: [ "Could not delete review" ] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || { base: [ "Could not delete review" ] }
    end
  end
end
