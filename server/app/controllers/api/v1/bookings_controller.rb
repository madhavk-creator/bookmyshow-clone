module Api
  module V1
    class BookingsController < ApplicationController
      before_action :authenticate!

      # GET /api/v1/bookings
      def index
        result = run Bookings::Index, params: index_params do |operation_result|
          return render json: {
            bookings: Bookings::Serializer.many(operation_result[:records]),
            pagination: operation_result[:pagination]
          }, status: :ok
        end

        render_operation_errors(result)
      end

      # GET /api/v1/bookings/:id
      def show
        result = run Bookings::Show, params: { id: params[:id] } do |operation_result|
          return render json: Bookings::Serializer.call(operation_result[:model], detailed: true), status: :ok
        end

        render_operation_errors(result)
      end

      # POST /api/v1/bookings
      def create
        result = run Bookings::Create, params: booking_params.to_h.deep_symbolize_keys do |operation_result|
          return render json: Bookings::Serializer.call(operation_result[:model], detailed: true), status: :created
        end

        render_operation_errors(result)
      end

      # Simulates the payment gateway callback.
      # POST /api/v1/bookings/:id/confirm_payment
      def confirm_payment
        result = run Bookings::ConfirmPayment, params: { id: params[:id] } do |operation_result|
          return render json: Bookings::Serializer.call(operation_result[:model], detailed: true), status: :ok
        end

        render_operation_errors(result)
      end

      # POST /api/v1/bookings/:id/cancel
      def cancel
        result = run Bookings::Cancel, params: { id: params[:id] } do |operation_result|
          return render json: Bookings::Serializer.call(operation_result[:model], detailed: true), status: :ok
        end

        render_operation_errors(result)
      end

      # POST /api/v1/bookings/:id/apply_coupon
      def apply_coupon
        result = run Bookings::ApplyCoupon, params: { id: params[:id], coupon_code: params[:coupon_code] } do |operation_result|
          return render json: Bookings::Serializer.call(operation_result[:model], detailed: true), status: :ok
        end

        render_operation_errors(result)
      end

      # POST /api/v1/bookings/:id/tickets/:ticket_id/cancel
      def cancel_ticket
        result = run Bookings::CancelTicket, params: { booking_id: params[:id], ticket_id: params[:ticket_id] } do |operation_result|
          return render json: Bookings::Serializer.call(operation_result[:model], detailed: true), status: :ok
        end

        render_operation_errors(result)
      end

      private

      def booking_params = params.require(:booking).permit(:show_id, :coupon_code, seat_ids: [])

      def index_params = params.permit(:page, :per_page, booking: {}).to_h.deep_symbolize_keys
    end
  end
end
