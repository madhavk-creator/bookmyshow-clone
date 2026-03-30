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
    end

    def build_layout(ctx, params:, screen:, **)
      ctx[:model] = ::SeatLayout.new(
        screen:         screen,
        name:           params[:name],
        total_rows:     params[:total_rows],
        total_columns:  params[:total_columns],
        screen_label:   params[:screen_label],
        legend_json:    params[:legend_json] || {}
      )
    end

    def persist(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end