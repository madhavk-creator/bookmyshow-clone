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

        render_operation_errors(result)
      end

      # GET /api/v1/bookings/:id
      def show
        booking = find_booking
        return unless booking

        authorize booking
        render json: serialize(booking.refresh_expiration!, detailed: true)
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
          render_operation_errors(result)
        end
      end

      # Simulates the payment gateway callback.
      # POST /api/v1/bookings/:id/confirm_payment
      def confirm_payment
        result = Bookings::ConfirmPayment.call(
          params: { id: params[:id] },
          current_user: current_user
        )

        if result.success?
          render json: serialize(result[:model], detailed: true)
        else
          render_operation_errors(result)
        end
      end

      # POST /api/v1/bookings/:id/cancel
      def cancel
        result = Bookings::Cancel.call(
          params: { id: params[:id] },
          current_user: current_user
        )

        if result.success?
          render json: serialize(result[:model], detailed: true)
        else
          render_operation_errors(result)
        end
      end

      # POST /api/v1/bookings/:id/apply_coupon
      def apply_coupon
        booking = find_booking
        return unless booking

        authorize booking, :update?

        result = Bookings::ApplyCoupon.call(
          params:       { id: booking.id, coupon_code: params[:coupon_code] },
          current_user: current_user
        )

        if result.success?
          render json: serialize(result[:model], detailed: true)
        else
          render_operation_errors(result)
        end
      end

      # POST /api/v1/bookings/:id/tickets/:ticket_id/cancel
      def cancel_ticket
        result = Bookings::CancelTicket.call(
          params: { booking_id: params[:id], ticket_id: params[:ticket_id] },
          current_user: current_user
        )

        if result.success?
          render json: serialize(result[:model], detailed: true)
        else
          render_operation_errors(result)
        end
      end

      private

      def find_booking
        booking = policy_scope(Booking).includes(
          :coupon, :payments,
          show: { screen: :theatre },
          tickets: :seat
        ).find_by(id: params[:id])

        render_errors({ booking: [ "Not found" ] }, status: :not_found) unless booking
        booking
      end

      def booking_params = params.require(:booking).permit(:show_id, :coupon_code, seat_ids: [])

      def render_errors(errors, status: :unprocessable_entity) = render(json: { errors: errors }, status:)

      def render_operation_errors(result) = render_errors(result[:errors], status: error_status_for(result[:errors]))

      def error_status_for(errors)
        flat_errors = errors.to_h.values.flatten
        return :not_found if flat_errors.include?("Not found")
        return :forbidden if flat_errors.any? { |message| message.to_s.start_with?("Not authorized") }

        :unprocessable_entity
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
            movie:      { id: booking.show.movie.id, title: booking.show.movie.title },
            screen:     { id: booking.show.screen.id, name: booking.show.screen.name, theatre: { id: booking.show.screen.theatre.id, name: booking.show.screen.theatre.name, building_name: booking.show.screen.theatre.building_name, street_address: booking.show.screen.theatre.street_address } }
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
