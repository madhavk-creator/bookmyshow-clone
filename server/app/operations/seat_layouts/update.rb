# Updates name, dimensions, or display metadata.
# Blocked on published/archived layouts via policy.
module SeatLayouts
  class Update < ::Trailblazer::Operation
    step :find_screen
    step :find_layout
    step :authorize_update
    step :assign_attributes
    step :persist
    fail :collect_errors

    def find_screen(ctx, params:, **)
      ctx[:screen] = ::Screen.joins(:theatre)
                            .find_by(id: params[:screen_id], theatres: { id: params[:theatre_id] })
      unless ctx[:screen]
        ctx[:errors] = { screen: [ "Screen not found" ] }
        return false
      end
      true
    end

    def find_layout(ctx, params:, screen:, **)
      ctx[:model] = screen.seat_layouts.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: [ "Layout not found" ] }
        return false
      end
      true
    end

    def authorize_update(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).update?

      ctx[:errors] = { base: [ "Not authorized to update this layout" ] }
      false
    end

    def assign_attributes(ctx, params:, model:, **)
      allowed = %i[name total_rows total_columns screen_label legend_json]
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
