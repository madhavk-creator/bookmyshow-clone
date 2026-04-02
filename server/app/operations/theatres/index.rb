module Theatres
  class Index < Trailblazer::Operation
    step :load_theatres

    private

    def load_theatres(ctx, current_user: nil, params: {}, **)
      conditions = {}
      conditions[:city_id] = params[:city_id] if params[:city_id].present?
      conditions[:vendor_id] = params[:vendor_id] if params[:vendor_id].present?

      ctx[:records] = Pundit.policy_scope!(current_user, Theatre)
                           .includes(:city, :vendor)
                           .where(conditions)
                           .order(:name)
    end
  end
end
