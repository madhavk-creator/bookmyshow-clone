module Languages
  class Index < ::Trailblazer::Operation
    step :load_languages

    def load_languages(ctx, current_user: nil, params: {}, **)
      scope = Pundit.policy_scope!(current_user, Language).order(:name)
      scope = scope.where("name ILIKE ?", "%#{params[:q]}%") if params[:q].present?
      ctx[:records] = scope
    end
  end
end
