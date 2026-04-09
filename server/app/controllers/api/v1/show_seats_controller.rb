module Api
  module V1
    class ShowSeatsController < ApplicationController
      before_action :authenticate!, only: %i[block unblock]

      # GET /api/v1/shows/:show_id/seats
      def availability
        result = run ShowSeatStates::Availability, params: { show_id: params[:show_id] || params[:id] } do |operation_result|
          return render json: operation_result[:payload], status: :ok
        end

        render_operation_errors(result)
      end

      # POST /api/v1/shows/:show_id/seats/:seat_id/block
      # Admin only.
      def block
        result = run(
          ShowSeatStates::Block,
          params: { show_id: params[:show_id] || params[:id], seat_id: params[:seat_id] }
        ) do
          return render json: { message: "Seat blocked", seat_id: params[:seat_id] }, status: :created
        end

        render_operation_errors(result)
      end

      # DELETE /api/v1/shows/:show_id/seats/:seat_id/block
      # Admin only.
      def unblock
        result = run(
          ShowSeatStates::Unblock,
          params: { show_id: params[:show_id] || params[:id], seat_id: params[:seat_id] }
        ) do
          return render json: { message: "Seat unblocked", seat_id: params[:seat_id] }, status: :ok
        end

        render_operation_errors(result)
      end
    end
  end
end
