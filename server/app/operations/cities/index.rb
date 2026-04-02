module Cities
  class Index < Trailblazer::Operation
    step :load_cities

    private

    def load_cities(ctx, current_user: nil, params: {}, **)
      scope = Pundit.policy_scope!(current_user, City).order(:state, :name)
      scope = scope.where(state: params[:state].to_s.titleize) if params[:state].present?
      ctx[:records] = scope
    end
  end
end
