module Theatres
  class Show < ::Trailblazer::Operation
    step :find_theatre
    step :authorize_theatre
    fail :collect_errors

    def find_theatre(ctx, params:, **)
      ctx[:model] = ::Theatre.includes(:city, :vendor).find_by(id: params[:id])
      return true if ctx[:model]

      ctx[:errors] = { base: [ "Theatre not found" ] }
      false
    end

    def authorize_theatre(ctx, model:, current_user: nil, **)
      return true if Pundit.policy!(current_user, model).show?

      ctx[:errors] = { base: [ "Not authorized to view this theatre" ] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end
