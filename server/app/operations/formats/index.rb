module Formats
  class Index < Trailblazer::Operation
    step :load_formats

    def load_formats(ctx, current_user: nil, params: {}, **)
      scope = Pundit.policy_scope!(current_user, Format).order(:name)
      scope = scope.where('name ILIKE ?', "%#{params[:q]}%") if params[:q].present?
      ctx[:records] = scope
    end
  end
end
