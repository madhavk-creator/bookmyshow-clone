# app/controllers/api/v1/show_seats_controller.rb
#
# Endpoints:
#   GET    /api/v1/shows/:show_id/seats              — full seat map + availability count
#   POST   /api/v1/shows/:show_id/seats/:seat_id/block   — admins block
#   DELETE /api/v1/shows/:show_id/seats/:seat_id/block   — admins unblock
#
# The seat map response is the primary data source for the seat picker UI.
# It returns every seat in the show's layout with its current status joined,
# grouped by section, plus a top-level availability summary.

module Api
  module V1
    class ShowSeatsController < ApplicationController
      before_action :authenticate!, only: %i[block unblock]
      before_action :find_show

      # GET /api/v1/shows/:show_id/seats
      def availability
        @show.release_expired_locks!

        layout   = @show.seat_layout
        sections = layout.seat_sections.order(:rank).includes(:seats, :show_section_prices)

        # Single query for all non-available seat states for this show
        state_by_seat_id = ShowSeatState
                             .where(show_id: @show.id)
                             .index_by(&:seat_id)
                             .to_h

        # Section prices indexed by seat_section_id
        price_by_section_id = ShowSectionPrice
                                .where(show_id: @show.id)
                                .pluck(:seat_section_id, :base_price)
                                .to_h

        counts = { available: 0, locked: 0, booked: 0, blocked: 0, inactive: 0 }

        serialized_sections = sections.map do |section|
          seats = section.seats.order(:grid_row, :grid_column)

          serialized_seats = seats.map do |seat|
            state = state_by_seat_id[seat.id]
            status = if !seat.is_active
                       'inactive'
                     else
                       state&.effective_status || 'available'
                     end
            counts[status.to_sym] += 1

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
              status:        status
            }
          end

          {
            id:         section.id,
            code:       section.code,
            name:       section.name,
            color_hex:  section.color_hex,
            rank:       section.rank,
            base_price: price_by_section_id[section.id],
            seats:      serialized_seats
          }
        end

        render json: {
          show_id:         @show.id,
          total_capacity:  @show.total_capacity,
          available_count: counts[:available],
          locked_count:    counts[:locked],
          booked_count:    counts[:booked],
          blocked_count:   counts[:blocked],
          inactive_count:  counts[:inactive],
          sections:        serialized_sections
        }
      end

      # POST /api/v1/shows/:show_id/seats/:seat_id/block
      # Admin only.
      def block
        authorize ShowSeatState, :block?

        result = run(
          ShowSeatStates::Block,
          params: { show_id: @show.id, seat_id: params[:seat_id] }
        ) do
          return render json: { message: 'Seat blocked', seat_id: params[:seat_id] }, status: :created
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # DELETE /api/v1/shows/:show_id/seats/:seat_id/block
      # Admin only.
      def unblock
        authorize ShowSeatState, :unblock?

        result = run(
          ShowSeatStates::Unblock,
          params: { show_id: @show.id, seat_id: params[:seat_id] }
        ) do
          return render json: { message: 'Seat unblocked', seat_id: params[:seat_id] }
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      private

      def find_show
        @show = Show.find_by(id: params[:id] || params[:show_id])
        render json: { error: 'Show not found' }, status: :not_found unless @show
      end
    end
  end
end
