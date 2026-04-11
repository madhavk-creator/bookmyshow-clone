module Bookings
  module Serializer
    module_function

    def call(booking, detailed: false)
      base = {
        id: booking.id,
        status: booking.status,
        total_amount: booking.total_amount,
        booking_time: booking.booking_time,
        lock_expires_at: booking.current_lock_expires_at,
        show: {
          id: booking.show.id,
          start_time: booking.show.start_time,
          movie: {
            id: booking.show.movie.id,
            title: booking.show.movie.title
          },
          screen: {
            id: booking.show.screen.id,
            name: booking.show.screen.name,
            theatre: {
              id: booking.show.screen.theatre.id,
              name: booking.show.screen.theatre.name,
              building_name: booking.show.screen.theatre.building_name,
              street_address: booking.show.screen.theatre.street_address
            }
          }
        },
        coupon: booking.coupon ? { code: booking.coupon.code } : nil,
        tickets_count: booking.tickets.size
      }

      return base unless detailed

      base[:tickets] = booking.tickets.map do |ticket|
        {
          id: ticket.id,
          seat_id: ticket.seat_id,
          seat_label: ticket.seat_label,
          section_name: ticket.section_name,
          price: ticket.price,
          status: ticket.status
        }
      end

      payment = booking.payments.max_by(&:created_at)
      base[:payment] = payment ? {
        id: payment.id,
        status: payment.status,
        amount: payment.amount,
        paid_at: payment.paid_at
      } : nil

      base
    end

    def many(bookings, detailed: false)
      bookings.map { |booking| call(booking, detailed: detailed) }
    end
  end
end
