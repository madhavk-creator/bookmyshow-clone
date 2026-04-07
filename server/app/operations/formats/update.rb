module Formats
  class Update < ::Trailblazer::Operation
    step :find_format
    step :authorize_format
    step :update_attributes
    step :persist
    fail :collect_errors

    def find_format(ctx, params:, model: nil, **)
      return true if model.present?

      ctx[:model] = ::Format.find_by(id: params[:id])
      return true if ctx[:model]

      ctx[:errors] = { base: [ "Format not found" ] }
      false
    end

    def authorize_format(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).update?

      ctx[:errors] = { base: [ "Not authorized to update this format" ] }
      false
    end

    def update_attributes(ctx, params:, model:, **)
      allowed = %i[name code]
      model.assign_attributes(params.slice(*allowed).compact)
      true
    end

    def persist(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, **)
      ctx[:errors] ||= {}
      ctx[:errors].merge!(ctx[:model].errors.to_hash(true)) if ctx[:model]
    end
  end
end
