# Updates name, dimensions, or display metadata.
# Blocked on published/archived layouts via policy.
module SeatLayouts
  class Update < Trailblazer::Operation
    step :find_layout
    step :assign_attributes
    step :persist
    fail :collect_errors

    def find_layout(ctx, params:, **)
      ctx[:model] = ::SeatLayout.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['Layout not found'] }
        return false
      end
      true
    end

    def assign_attributes(ctx, params:, model:, **)
      allowed = %i[name total_rows total_columns screen_label legend_json]
      model.assign_attributes(params.slice(*allowed).compact)
    end

    def persist(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end