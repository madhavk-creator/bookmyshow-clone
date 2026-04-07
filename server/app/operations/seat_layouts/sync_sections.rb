# Replace-on-write: destroys all existing sections (and their seats via cascade)
# and reinserts from the provided array.
# Only allowed on draft layouts.
#
# Params: id, sections: [{ code:, name:, color_hex:, rank:, seat_type: }, ...]
module SeatLayouts
  class SyncSections < ::Trailblazer::Operation
    step :find_screen
    step :find_layout
    step :authorize_sync_sections
    step :validate_sections_param
    step :replace_sections
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

    def authorize_sync_sections(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).sync_sections?

      ctx[:errors] = { base: [ "Not authorized to sync sections for this layout" ] }
      false
    end

    def validate_sections_param(ctx, params:, **)
      sections = Array(params[:sections])
      if sections.empty?
        ctx[:errors] = { sections: [ "At least one section is required" ] }
        return false
      end

      normalized_codes = sections
        .map { |s| s[:code] || s["code"] }
        .select(&:present?)
        .map { |code| code.to_s.parameterize(separator: "_") }
      if normalized_codes.uniq.length != normalized_codes.length
        ctx[:errors] = { sections: [ "Section codes must be unique" ] }
        return false
      end

      ranks = sections.map { |s| s[:rank] || s["rank"] }.select(&:present?)
      if ranks.uniq.length != ranks.length
        ctx[:errors] = { sections: [ "Section ranks must be unique" ] }
        return false
      end
      true
    end

    def replace_sections(ctx, params:, model:, **)
      sections = Array(params[:sections])

      model.class.transaction do
        # Destroying sections cascades to seats — vendors must re-add seats after
        # changing sections. This is intentional: section changes invalidate seat
        # section assignments.
        model.seat_sections.destroy_all

        sections.each_with_index do |s, i|
          model.seat_sections.create!(
            code:      s[:code]      || s["code"],
            name:      s[:name]      || s["name"],
            color_hex: s[:color_hex] || s["color_hex"],
            rank:      s[:rank]      || s["rank"] || i,
            seat_type: s[:seat_type] || s["seat_type"]
          )
        end

        model.update!(total_seats: 0)
      end

      true
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      ctx[:errors] = { sections: [ e.message ] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= { base: [ "Could not sync sections" ] }
    end
  end
end
