module Api
  module V1
    class ShowsController < ApplicationController
      before_action :authenticate!, only: %i[create update cancel]

      # Nested context — only required for write actions and scoped reads.
      before_action :find_screen, only: %i[create update cancel]

      # GET /api/v1/shows
      # GET /api/v1/theatres/:theatre_id/screens/:screen_id/shows
      # Public. Defaults to scheduled shows only. All filters optional.
      def index
        result = run(
          Shows::Index,
          current_user: current_user,
          params: {
            screen_id: params[:screen_id],
            status: params[:status],
            movie_id: params[:movie_id],
            date: params[:date],
            language: params[:language],
            format: params[:format],
            city_id: params[:city_id],
            page: params[:page],
            per_page: params[:per_page]
          }
        ) do |operation_result|
          return render json: {
            shows: operation_result[:records].map { |show_record| serialize(show_record) },
            pagination: operation_result[:pagination]
          }
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # GET /api/v1/shows/:id
      # GET /api/v1/theatres/:theatre_id/screens/:screen_id/shows/:id
      # Public. Full detail including section prices.
      def show
        show_record = find_show_globally
        return unless show_record

        render json: serialize(show_record, detailed: true)
      end

      # POST /api/v1/theatres/:theatre_id/screens/:screen_id/shows
      def create
        authorize Show.new(screen: @screen)

        result = run(
          Shows::Create,
          params: show_params.to_h.deep_symbolize_keys.merge(screen_id: @screen.id)
        ) do |operation_result|
          return render json: serialize(operation_result[:model], detailed: true), status: :created
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # PATCH /api/v1/theatres/:theatre_id/screens/:screen_id/shows/:id
      # Only start_time and section_prices are mutable after creation.
      def update
        show_record = @screen.shows.find_by(id: params[:id])
        return not_found unless show_record

        authorize show_record

        result = run(
          Shows::Update,
          params: show_params.to_h.deep_symbolize_keys.merge(id: show_record.id)
        ) do |operation_result|
          return render json: serialize(operation_result[:model], detailed: true)
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # POST /api/v1/theatres/:theatre_id/screens/:screen_id/shows/:id/cancel
      def cancel
        show_record = @screen.shows.find_by(id: params[:id])
        return not_found unless show_record

        authorize show_record

        result = run(Shows::Cancel, params: { id: show_record.id }) do |operation_result|
          return render json: serialize(operation_result[:model])
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      private

      # Only called for write actions — requires full nested context.
      def find_screen
        @screen = Screen.joins(theatre: {})
                        .find_by(
                          id:       params[:screen_id],
                          theatres: { id: params[:theatre_id] }
                        )
        render json: { error: 'Screen not found' }, status: :not_found unless @screen
      end

      # Works from both top-level and nested routes.
      # Top-level routes stay global for discovery.
      # Nested routes enforce the provided theatre/screen chain.
      def find_show_globally
        scope = Show.all

        if params[:screen_id].present?
          scope = scope.where(screen_id: params[:screen_id])
        end

        if params[:theatre_id].present?
          scope = scope.joins(screen: :theatre)
                       .where(theatres: { id: params[:theatre_id] })
        end

        show  = scope.find_by(id: params[:id])
        not_found unless show
        show
      end

      def show_params
        params.require(:show).permit(
          :movie_id, :seat_layout_id, :movie_language_id,
          :movie_format_id, :start_time,
          section_prices: [:seat_section_id, :base_price]
        )
      end

      def serialize(show, detailed: false)
        base = {
          id:             show.id,
          screen_id:      show.screen_id,
          movie:          { id: show.movie.id, title: show.movie.title, running_time: show.movie.running_time },
          language:       { id: show.movie_language.id, code: show.movie_language.language.code },
          format:         { id: show.movie_format.id,   code: show.movie_format.format.code },
          seat_layout_id: show.seat_layout_id,
          start_time:     show.start_time,
          end_time:       show.end_time,
          total_capacity: show.total_capacity,
          status:         show.status
        }

        if detailed
          base[:section_prices] = show.show_section_prices.map do |sp|
            {
              seat_section_id:   sp.seat_section_id,
              seat_section_code: sp.seat_section.code,
              seat_section_name: sp.seat_section.name,
              base_price:        sp.base_price
            }
          end
        end

        base
      end

      def not_found
        render json: { error: 'Show not found' }, status: :not_found
      end
    end
  end
end
