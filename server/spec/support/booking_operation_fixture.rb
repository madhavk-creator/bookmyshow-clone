module BookingOperationFixture
  def random_letters(length = 4)
    Array.new(length) { ("a".."z").to_a.sample }.join
  end

  def build_booking_fixture(seat_count: 3)
    customer = User.create!(
      name: "Customer",
      email: "customer-#{SecureRandom.hex(4)}@example.com",
      password: "password",
      password_confirmation: "password",
      phone: "9876543210",
      role: :user,
      is_active: true
    )

    vendor = User.create!(
      name: "Vendor",
      email: "vendor-#{SecureRandom.hex(4)}@example.com",
      password: "password",
      password_confirmation: "password",
      phone: "9876543211",
      role: :vendor,
      is_active: true
    )

    city = City.create!(name: "City#{SecureRandom.hex(3)}", state: "State")
    theatre = Theatre.create!(
      vendor: vendor,
      city: city,
      name: "Theatre #{SecureRandom.hex(3)}",
      building_name: "Mall Plaza",
      street_address: "Main Street",
      pincode: "400001"
    )
    screen = Screen.create!(
      theatre: theatre,
      name: "Screen #{SecureRandom.hex(2)}",
      total_rows: 5,
      total_columns: 5,
      total_seats: seat_count,
      status: "active"
    )

    language = Language.create!(name: "English #{SecureRandom.hex(2)}", code: "en#{random_letters(4)}")
    format = Format.create!(name: "IMAX#{SecureRandom.hex(2)}", code: "imax#{SecureRandom.hex(2)}")
    movie = Movie.create!(
      title: "Movie #{SecureRandom.hex(4)}",
      genre: "Drama",
      rating: "UA",
      description: "A sufficiently descriptive movie summary for tests.",
      director: "Director Name",
      running_time: 120,
      release_date: Date.new(2026, 4, 1)
    )
    movie_language = MovieLanguage.create!(movie: movie, language: language, language_type: "original")
    movie_format = MovieFormat.create!(movie: movie, format: format)
    ScreenCapability.create!(screen: screen, format: format)

    seat_layout = SeatLayout.create!(
      screen: screen,
      name: "Published Layout",
      version_number: 1,
      status: "published",
      total_rows: 5,
      total_columns: 5,
      total_seats: seat_count,
      published_at: Time.current
    )
    section = SeatSection.create!(
      seat_layout: seat_layout,
      code: "prime",
      name: "Prime",
      color_hex: "#FFAA00",
      rank: 1
    )

    seats = Array.new(seat_count) do |index|
      Seat.create!(
        seat_layout: seat_layout,
        seat_section: section,
        row_label: "A",
        seat_number: index + 1,
        grid_row: 1,
        grid_column: index + 1,
        seat_kind: "standard",
        is_accessible: false,
        is_active: true
      )
    end

    show = Show.create!(
      screen: screen,
      seat_layout: seat_layout,
      movie: movie,
      movie_language: movie_language,
      movie_format: movie_format,
      start_time: 2.days.from_now,
      end_time: 2.days.from_now + movie.running_time.minutes,
      total_capacity: seat_count,
      status: "scheduled"
    )
    ShowSectionPrice.create!(show: show, seat_section: section, base_price: 100)

    {
      customer: customer,
      vendor: vendor,
      city: city,
      theatre: theatre,
      screen: screen,
      language: language,
      format: format,
      movie: movie,
      movie_language: movie_language,
      movie_format: movie_format,
      seat_layout: seat_layout,
      section: section,
      seats: seats,
      show: show
    }
  end

  def create_coupon(code:, coupon_type:, valid_from: 1.day.ago, valid_until: 2.days.from_now, **attrs)
    Coupon.create!(
      {
        code: code,
        coupon_type: coupon_type,
        valid_from: valid_from,
        valid_until: valid_until
      }.merge(attrs)
    )
  end

  def create_booking_bundle(user:, show:, seats:, coupon: nil, booking_status:, payment_status:, lock_token: SecureRandom.uuid, seat_state_status: nil)
    subtotal = seats.sum { |seat| show.show_section_prices.find_by!(seat_section_id: seat.seat_section_id).base_price.to_d }
    total_amount = coupon ? coupon.apply(subtotal) : subtotal

    booking = Booking.create!(
      user: user,
      show: show,
      coupon: coupon,
      total_amount: total_amount,
      status: booking_status,
      lock_token: lock_token
    )

    tickets = seats.map do |seat|
      Ticket.create!(
        booking: booking,
        show: show,
        seat: seat,
        seat_label: seat.label,
        section_name: seat.seat_section.name,
        price: show.show_section_prices.find_by!(seat_section_id: seat.seat_section_id).base_price,
        status: "valid"
      )
    end

    payment = Payment.create!(
      booking: booking,
      user: user,
      amount: total_amount,
      status: payment_status
    )

    if payment_status == "completed"
      Transaction.create!(
        payment: payment,
        ref_no: "TXN-#{SecureRandom.hex(6)}",
        payment_method: "card",
        amount: payment.amount,
        transaction_time: Time.current,
        status: "completed"
      )
    end

    if coupon.present?
      UserCouponUsage.create!(coupon: coupon, user: user, booking: booking, used_at: Time.current)
    end

    if seat_state_status.present?
      seats.each do |seat|
        ShowSeatState.create!(
          show: show,
          seat: seat,
          status: seat_state_status,
          locked_by_user: user,
          lock_token: (seat_state_status == "locked" ? lock_token : nil),
          locked_until: (seat_state_status == "locked" ? 5.minutes.from_now : nil)
        )
      end
    end

    { booking: booking, tickets: tickets, payment: payment }
  end
end

RSpec.configure do |config|
  config.include BookingOperationFixture
end
