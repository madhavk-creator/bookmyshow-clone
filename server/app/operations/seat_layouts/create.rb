class SeatLayout
  class Create < Trailblazer::Operation
    step :find_screen
    step :build_layout
    step :persist
    fail :collect_errors

    private

    def find_screen(ctx, params:, **)
      ctx[:screen] = Screen.find_by(id: params[:screen_id])
      unless ctx[:screen]
        ctx[:errors] = { screen: ['Screen not found'] }
        return false
      end
      true
    end

    def build_layout(ctx, params:, screen:, **)
      ctx[:model] = ::SeatLayout.new(
        screen:         screen,
        version_number: next_version_number(screen),
        name:           params[:name],
        total_rows:     params[:total_rows],
        total_columns:  params[:total_columns],
        total_seats:    0,
        status:         "draft",
        screen_label:   params[:screen_label],
        legend_json:    params[:legend_json] || {}
      )
    end

    def persist(ctx, model:, **)
      return true if model.save

      model.valid? if model.errors.empty?
      ctx[:errors] = model.errors.to_hash(true).presence || { base: ['Could not create seat layout'] }
      false
    rescue StandardError => e
      ctx[:errors] = { base: [e.message] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      current_model = model || ctx[:model]
      ctx[:errors] ||= current_model&.errors&.to_hash(true) || { base: ['Could not create seat layout'] }
    end

    def next_version_number(screen)
      (screen.seat_layouts.maximum(:version_number) || 0) + 1
    end
  end
end
