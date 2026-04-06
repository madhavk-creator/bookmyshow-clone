module Api
  module V1
    class SeatLayoutsController < ApplicationController
      before_action :authenticate!, except: %i[index show]
      before_action :authenticate_optional!, only: %i[index show]
      before_action :find_screen

      # GET /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts
      def index
        result = run(SeatLayouts::Index, current_user: current_user, params: { screen_id: @screen.id }) do |operation_result|
          return render json: operation_result[:records].map { |layout| serialize(layout) }
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # GET /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id
      # Returns full detail — sections + seats for the grid renderer.
      def show
        layout = find_layout
        return unless layout

        authorize layout

        render json: serialize(layout, detailed: true)
      end

      # POST /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts
      def create
        authorize SeatLayout.new(screen: @screen)

        result = run(
          SeatLayouts::Create,
          params: layout_params.to_h.merge(screen_id: @screen.id)
        ) do |operation_result|
          return render json: serialize(operation_result[:model]), status: :created
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # PATCH /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id
      def update
        layout = find_layout
        return unless layout

        authorize layout

        result = run(
          SeatLayouts::Update,
          params: layout_params.to_h.merge(id: layout.id)
        ) do |operation_result|
          return render json: serialize(operation_result[:model])
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # POST /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id/publish
      def publish
        layout = find_layout
        return unless layout

        authorize layout

        result = run(SeatLayouts::Publish, params: { id: layout.id }) do |operation_result|
          return render json: serialize(operation_result[:model])
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # POST /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id/archive
      def archive
        layout = find_layout
        return unless layout

        authorize layout

        result = run(SeatLayouts::Archive, params: { id: layout.id }) do |operation_result|
          return render json: serialize(operation_result[:model])
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # PUT /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id/sections
      # Full replacement of sections. Cascades to seats.
      # Payload: { sections: [{ code:, name:, color_hex:, rank:, seat_type: }] }
      def sync_sections
        layout = find_layout
        return unless layout

        authorize layout, :sync_sections?

        result = run(
          SeatLayouts::SyncSections,
          params: { id: layout.id, sections: sections_params }
        ) do |operation_result|
          return render json: serialize(operation_result[:model], detailed: true)
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # PUT /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id/seats
      # Full replacement of the seat map.
      # Payload: { seats: [{ row_label:, seat_number:, grid_row:, grid_column:,
      #                       seat_section_id:, seat_kind:, x_span:, y_span:,
      #                       is_accessible:, is_active: }] }
      def sync_seats
        layout = find_layout
        return unless layout

        authorize layout, :sync_seats?

        result = run(
          SeatLayouts::SyncSeats,
          params: { id: layout.id, seats: seats_params }
        ) do |operation_result|
          return render json: serialize(operation_result[:model], detailed: true)
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      private

      def find_screen
        @screen = Screen.joins(theatre: {})
                        .find_by(id: params[:screen_id], theatres: { id: params[:theatre_id] })
        render json: { error: "Screen not found" }, status: :not_found unless @screen
      end

      def find_layout
        layout = @screen.seat_layouts.find_by(id: params[:id])
        render json: { error: "Layout not found" }, status: :not_found unless layout
        layout
      end

      def layout_params
        params.require(:seat_layout).permit(
          :name, :total_rows, :total_columns, :screen_label,
          legend_json: {}
        )
      end

      def sections_params
        params.require(:sections).map do |s|
          s.permit(:code, :name, :color_hex, :rank, :seat_type).to_h
        end
      end

      def seats_params
        params.require(:seats).map do |s|
          s.permit(
            :row_label, :seat_number, :grid_row, :grid_column,
            :seat_section_id, :seat_kind, :x_span, :y_span,
            :is_accessible, :is_active
          ).to_h
        end
      end

      def serialize(layout, detailed: false)
        base = {
          id:             layout.id,
          screen_id:      layout.screen_id,
          version_number: layout.version_number,
          name:           layout.name,
          status:         layout.status,
          total_rows:     layout.total_rows,
          total_columns:  layout.total_columns,
          total_seats:    layout.total_seats,
          screen_label:   layout.screen_label,
          published_at:   layout.published_at,
          created_at:     layout.created_at
        }

        if detailed
          sections = layout.seat_sections.order(:rank).includes(:seats)
          base[:sections] = sections.map do |sec|
            {
              id:        sec.id,
              code:      sec.code,
              name:      sec.name,
              color_hex: sec.color_hex,
              rank:      sec.rank,
              seat_type: sec.seat_type,
              seats:     sec.seats.order(:grid_row, :grid_column).map { |seat| serialize_seat(seat) }
            }
          end
        end

        base
      end

      def serialize_seat(seat)
        {
          id:            seat.id,
          label:         seat.label,
          row_label:     seat.row_label,
          seat_number:   seat.seat_number,
          grid_row:      seat.grid_row,
          grid_column:   seat.grid_column,
          x_span:        seat.x_span,
          y_span:        seat.y_span,
          seat_kind:     seat.seat_kind,
          is_accessible: seat.is_accessible,
          is_active:     seat.is_active
        }
      end
    end
  end
end
