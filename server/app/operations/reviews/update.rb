module Reviews
  class Update < Trailblazer::Operation
    step :find_review
    step :assign_attributes
    step :persist
    fail :collect_errors

    def find_review(ctx, params:, current_user:, **)
      ctx[:model] = ::Review.find_by(id: params[:id], user_id: current_user.id)
      unless ctx[:model]
        ctx[:errors] = { base: ['Review not found'] }
        return false
      end

      true
    end

    def assign_attributes(ctx, params:, model:, **)
      model.description = params[:description] if params.key?(:description)
      model.rating      = params[:rating]      if params.key?(:rating)

      true
    end

    def persist(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end
