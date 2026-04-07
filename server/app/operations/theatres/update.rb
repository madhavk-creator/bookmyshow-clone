module Theatres
  class Update < ::Trailblazer::Operation
    step :find_theatre
    step :authorize_theatre
    step :update_attributes
    step :persist
    fail :collect_errors

    def find_theatre(ctx, params:, model: nil, **)
      return true if model.present?

      ctx[:model] = Theatre.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: [ "Theatre not found" ] }
        return false
      end

      true
    end

    def authorize_theatre(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).update?

      ctx[:errors] = { base: [ "Not authorized to update this theatre" ] }
      false
    end

    def update_attributes(ctx, params:, model:, **)
      allowed = %i[name building_name street_address pincode]
      model.assign_attributes(params.slice(*allowed).compact)
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
