module Api
  module V1
    class BookingsController < ApplicationController
      before_action :authenticate!

      # GET /api/v1/bookings
      def index
        result = run(
          Bookings::Index,
          current_user: current_user,
          params: { page: params[:page], per_page: params[:per_page] }
        ) do |operation_result|
          return render json: {
            bookings: operation_result[:records].map { |booking| serialize(booking) },
            pagination: operation_result[:pagination]
          }
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # GET /api/v1/bookings/:id
      def show
        booking = find_booking
        return unless booking

        authorize booking
        render json: serialize(booking, detailed: true)
      end

      # POST /api/v1/bookings
      def create
        authorize Booking

        result = Bookings::Create.call(
          params:       booking_params.to_h.deep_symbolize_keys,
          current_user: current_user
        )

        if result.success?
          render json: serialize(result[:model], detailed: true), status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/bookings/:id/confirm_payment
      # Simulates the payment gateway callback.
      # In production, replace with a real webhook endpoint.
      def confirm_payment
        booking = find_booking
        return unless booking

        authorize booking

        result = Bookings::ConfirmPayment.call(params: { id: booking.id })

        if result.success?
          render json: serialize(result[:model], detailed: true)
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/bookings/:id/cancel
      def cancel
        booking = find_booking
        return unless booking

        authorize booking

        result = Bookings::Cancel.call(params: { id: booking.id })

        if result.success?
          render json: serialize(result[:model], detailed: true)
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/bookings/:id/tickets/:ticket_id/cancel
      def cancel_ticket
        booking = find_booking
        return unless booking

        authorize booking, :cancel_ticket?

        result = Bookings::CancelTicket.call(
          params: { booking_id: booking.id, ticket_id: params[:ticket_id] }
        )

        if result.success?
          render json: serialize(result[:model], detailed: true)
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      private

      def find_booking
        booking = policy_scope(Booking).includes(
          :coupon, :payments,
          show: { screen: :theatre },
          tickets: :seat
        ).find_by(id: params[:id])

        render json: { error: 'Booking not found' }, status: :not_found unless booking
        booking
      end

      def booking_params
        params.require(:booking).permit(:show_id, :coupon_code, seat_ids: [])
      end

      def serialize(booking, detailed: false)
        base = {
          id:           booking.id,
          status:       booking.status,
          total_amount: booking.total_amount,
          booking_time: booking.booking_time,
          show: {
            id:         booking.show.id,
            start_time: booking.show.start_time,
            movie:      { id: booking.show.movie_id }
          },
          coupon: booking.coupon ? { code: booking.coupon.code } : nil,
          tickets_count: booking.tickets.size
        }

        if detailed
          base[:tickets] = booking.tickets.map do |t|
            {
              id:           t.id,
              seat_label:   t.seat_label,
              section_name: t.section_name,
              price:        t.price,
              status:       t.status
            }
          end

          payment = booking.payments.max_by(&:created_at)
          base[:payment] = payment ? {
            id:      payment.id,
            status:  payment.status,
            amount:  payment.amount,
            paid_at: payment.paid_at
          } : nil
        end

        base
      end
    end
  end
end
