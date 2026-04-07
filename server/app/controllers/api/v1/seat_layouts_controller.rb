module Api
  module V1
    class SeatLayoutsController < ApplicationController
      before_action :authenticate!, except: %i[index show]
      before_action :authenticate_optional!, only: %i[index show]

      # GET /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts
      def index
        result = run SeatLayouts::Index, params: { theatre_id: params[:theatre_id], screen_id: params[:screen_id] } do |operation_result|
          return render json: SeatLayouts::Serializer.many(operation_result[:records]), status: :ok
        end

        render_operation_errors(result)
      end

      # GET /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id
      # Returns full detail — sections + seats for the grid renderer.
      def show
        result = run SeatLayouts::Show, params: { theatre_id: params[:theatre_id], screen_id: params[:screen_id], id: params[:id] } do |operation_result|
          return render json: SeatLayouts::Serializer.call(operation_result[:model], detailed: true), status: :ok
        end

        render_operation_errors(result)
      end

      # POST /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts
      def create
        result = run(
          SeatLayouts::Create,
          params: layout_params.to_h.deep_symbolize_keys.merge(theatre_id: params[:theatre_id], screen_id: params[:screen_id])
        ) do |operation_result|
          return render json: SeatLayouts::Serializer.call(operation_result[:model]), status: :created
        end

        render_operation_errors(result)
      end

      # PATCH /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id
      def update
        result = run(
          SeatLayouts::Update,
          params: layout_params.to_h.deep_symbolize_keys.merge(
            theatre_id: params[:theatre_id],
            screen_id: params[:screen_id],
            id: params[:id]
          )
        ) do |operation_result|
          return render json: SeatLayouts::Serializer.call(operation_result[:model]), status: :ok
        end

        render_operation_errors(result)
      end

      # POST /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id/publish
      def publish
        result = run SeatLayouts::Publish, params: { theatre_id: params[:theatre_id], screen_id: params[:screen_id], id: params[:id] } do |operation_result|
          return render json: SeatLayouts::Serializer.call(operation_result[:model]), status: :ok
        end

        render_operation_errors(result)
      end

      # POST /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id/archive
      def archive
        result = run SeatLayouts::Archive, params: { theatre_id: params[:theatre_id], screen_id: params[:screen_id], id: params[:id] } do |operation_result|
          return render json: SeatLayouts::Serializer.call(operation_result[:model]), status: :ok
        end

        render_operation_errors(result)
      end

      # PUT /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id/sections
      # Full replacement of sections. Cascades to seats.
      # Payload: { sections: [{ code:, name:, color_hex:, rank:, seat_type: }] }
      def sync_sections
        result = run(
          SeatLayouts::SyncSections,
          params: {
            theatre_id: params[:theatre_id],
            screen_id: params[:screen_id],
            id: params[:id],
            sections: sections_params
          }
        ) do |operation_result|
          return render json: SeatLayouts::Serializer.call(operation_result[:model], detailed: true), status: :ok
        end

        render_operation_errors(result)
      end

      # PUT /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id/seats
      # Full replacement of the seat map.
      # Payload: { seats: [{ row_label:, seat_number:, grid_row:, grid_column:,
      #                       seat_section_id:, seat_kind:, x_span:, y_span:,
      #                       is_accessible:, is_active: }] }
      def sync_seats
        result = run(
          SeatLayouts::SyncSeats,
          params: {
            theatre_id: params[:theatre_id],
            screen_id: params[:screen_id],
            id: params[:id],
            seats: seats_params
          }
        ) do |operation_result|
          return render json: SeatLayouts::Serializer.call(operation_result[:model], detailed: true), status: :ok
        end

        render_operation_errors(result)
      end

      private

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

      def render_operation_errors(result)
        errors = result[:errors].presence || { base: [ "Seat layout request failed" ] }
        render json: { errors: errors }, status: error_status_for(errors)
      end

      def error_status_for(errors)
        messages = errors.values.flatten.map(&:to_s)
        return :not_found if messages.any? { |message| message.downcase.include?("not found") }
        return :forbidden if messages.any? { |message| message.start_with?("Not authorized") || message == "Forbidden" }

        :unprocessable_entity
      end
    end
  end
end
