module Api
  module V1
    class SeatLayoutsController < ApplicationController
      before_action :authenticate!,          except: %i[index show]
      before_action :authenticate_optional!, only:   %i[index show]

      # GET /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts
      def index
        result = run SeatLayouts::Index, params: scope_params do |operation_result|
          return render json: SeatLayouts::Serializer.many(operation_result[:records]), status: :ok
        end

        render_operation_errors(result)
      end

      # GET /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id
      def show
        result = run SeatLayouts::Show, params: scope_params do |operation_result|
          return render json: SeatLayouts::Serializer.call(operation_result[:model], detailed: true), status: :ok
        end

        render_operation_errors(result)
      end

      # POST /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts
      def create
        result = run SeatLayouts::Create, params: scope_params.merge(layout_params) do |operation_result|
          return render json: SeatLayouts::Serializer.call(operation_result[:model]), status: :created
        end

        render_operation_errors(result)
      end

      # PATCH /api/v1/theatres/:theatre_id/screens/:screen_id/seat_layouts/:id
      def update
        result = run SeatLayouts::Update, params: scope_params.merge(layout_params) do |operation_result|
          return render json: SeatLayouts::Serializer.call(operation_result[:model]), status: :ok
        end

        render_operation_errors(result)
      end

      # POST …/:id/publish
      def publish
        result = run SeatLayouts::Publish, params: scope_params do |operation_result|
          return render json: SeatLayouts::Serializer.call(operation_result[:model]), status: :ok
        end

        render_operation_errors(result)
      end

      # POST …/:id/archive
      def archive
        result = run SeatLayouts::Archive, params: scope_params do |operation_result|
          return render json: SeatLayouts::Serializer.call(operation_result[:model]), status: :ok
        end

        render_operation_errors(result)
      end

      # PUT …/:id/sections
      def sync_sections
        result = run SeatLayouts::SyncSections, params: scope_params.merge(sections: sections_params) do |operation_result|
          return render json: SeatLayouts::Serializer.call(operation_result[:model], detailed: true), status: :ok
        end

        render_operation_errors(result)
      end

      # PUT …/:id/seats
      def sync_seats
        result = run SeatLayouts::SyncSeats, params: scope_params.merge(seats: seats_params) do |operation_result|
          return render json: SeatLayouts::Serializer.call(operation_result[:model], detailed: true), status: :ok
        end

        render_operation_errors(result)
      end

      private

      # Route segment params shared by every action.
      def scope_params
        params.permit(:theatre_id, :screen_id, :id, seat_layout: {}).to_h.symbolize_keys
      end

      def layout_params
        params.require(:seat_layout)
              .permit(:name, :total_rows, :total_columns, :screen_label, legend_json: {})
              .to_h.deep_symbolize_keys
      end

      def sections_params
        params.require(:sections).map { |section| section.permit(:code, :name, :color_hex, :rank, :seat_type).to_h }
      end

      def seats_params
        params.require(:seats).map do |s|
          s.permit(:row_label, :seat_number, :grid_row, :grid_column,
                   :seat_section_id, :seat_kind, :x_span, :y_span,
                   :is_accessible, :is_active).to_h
        end
      end
    end
  end
end
