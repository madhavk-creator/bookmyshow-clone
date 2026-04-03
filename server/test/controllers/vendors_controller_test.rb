require "test_helper"

class VendorsControllerTest < ActionDispatch::IntegrationTest
  test "should list active vendors" do
    active_vendor = User.create!(
      name: "Active Vendor",
      email: "active-vendor@example.com",
      password: "password",
      password_confirmation: "password",
      role: :vendor,
      phone: "9876543210",
      is_active: true
    )

    inactive_vendor = User.create!(
      name: "Inactive Vendor",
      email: "inactive-vendor@example.com",
      password: "password",
      password_confirmation: "password",
      role: :vendor,
      is_active: false
    )

    Theatre.create!(
      vendor: active_vendor,
      city: City.create!(name: "Mumbai", state: "Maharashtra"),
      name: "Active Screens",
      building_name: "Mall Plaza",
      street_address: "MG Road",
      pincode: "400001"
    )

    get "/api/v1/vendors", as: :json

    assert_response :success

    vendors = response.parsed_body["vendors"]
    assert_equal 1, vendors.size
    assert_equal active_vendor.id, vendors.first["id"]
    assert_equal 1, vendors.first["theatres_count"]
    assert_not_includes vendors.map { |vendor| vendor["id"] }, inactive_vendor.id
  end

  test "vendor can fetch their own total income" do
    vendor = User.create!(
      name: "Income Vendor",
      email: "income-vendor@example.com",
      password: "password",
      password_confirmation: "password",
      role: :vendor,
      is_active: true
    )

    customer = User.create!(
      name: "Customer",
      email: "customer@example.com",
      password: "password",
      password_confirmation: "password",
      role: :user,
      is_active: true
    )

    city = City.create!(name: "Pune", state: "Maharashtra")
    theatre = Theatre.create!(
      vendor: vendor,
      city: city,
      name: "Vendor Theatre",
      building_name: "Central Mall",
      street_address: "Main Street",
      pincode: "411001"
    )
    screen = Screen.create!(
      theatre: theatre,
      name: "Screen 1",
      total_rows: 5,
      total_columns: 5,
      total_seats: 25,
      status: "active"
    )
    language = Language.create!(name: "English", code: "en")
    format = Format.create!(name: "2D", code: "2d")
    movie = Movie.create!(
      title: "Revenue Test",
      genre: "Drama",
      rating: "UA",
      description: "Test movie",
      director: "Director",
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
      total_seats: 25,
      published_at: Time.current
    )
    section = SeatSection.create!(
      seat_layout: seat_layout,
      code: "prime",
      name: "Prime",
      color_hex: "#FFAA00",
      rank: 1
    )
    seat_one = Seat.create!(
      seat_layout: seat_layout,
      seat_section: section,
      row_label: "A",
      seat_number: 1,
      grid_row: 1,
      grid_column: 1,
      seat_kind: "standard",
      is_accessible: false,
      is_active: true
    )
    seat_two = Seat.create!(
      seat_layout: seat_layout,
      seat_section: section,
      row_label: "A",
      seat_number: 2,
      grid_row: 1,
      grid_column: 2,
      seat_kind: "standard",
      is_accessible: false,
      is_active: true
    )
    show = Show.create!(
      screen: screen,
      seat_layout: seat_layout,
      movie: movie,
      movie_language: movie_language,
      movie_format: movie_format,
      start_time: 2.days.from_now,
      end_time: 2.days.from_now + 2.hours,
      total_capacity: 25,
      status: "scheduled"
    )

    booking = Booking.create!(
      user: customer,
      show: show,
      total_amount: 450,
      booking_time: Time.current,
      status: "confirmed",
      lock_token: SecureRandom.uuid
    )

    payment = Payment.create!(
      booking: booking,
      user: customer,
      amount: 450,
      status: "completed",
      paid_at: Time.current
    )

    Transaction.create!(
      payment: payment,
      ref_no: "REV-#{SecureRandom.hex(4)}",
      payment_method: "card",
      amount: 450,
      transaction_time: Time.current,
      status: "completed"
    )

    ticket_one = Ticket.create!(
      booking: booking,
      show: show,
      seat: seat_one,
      seat_label: seat_one.label,
      section_name: section.name,
      price: 200,
      status: "valid"
    )
    ticket_two = Ticket.create!(
      booking: booking,
      show: show,
      seat: seat_two,
      seat_label: seat_two.label,
      section_name: section.name,
      price: 250,
      status: "cancelled"
    )

    PaymentRefund.create!(
      payment: payment,
      ticket: ticket_two,
      amount: 250,
      status: "completed"
    )

    get "/api/v1/vendors/#{vendor.id}/income",
        headers: { "Authorization" => "Bearer #{token_for(vendor)}" },
        as: :json

    assert_response :success

    body = response.parsed_body
    assert_equal vendor.id, body.dig("vendor", "id")
    assert_equal 1, body["theatres_count"]
    assert_equal 1, body["completed_bookings_count"]
    assert_equal 1, body["tickets_sold_count"]
    assert_equal "450.0", body["gross_income"]
    assert_equal "250.0", body["refund_amount"]
    assert_equal "200.0", body["total_income"]
  end

  test "vendor cannot fetch another vendor income" do
    vendor = User.create!(
      name: "Vendor One",
      email: "vendor-one@example.com",
      password: "password",
      password_confirmation: "password",
      role: :vendor,
      is_active: true
    )
    other_vendor = User.create!(
      name: "Vendor Two",
      email: "vendor-two@example.com",
      password: "password",
      password_confirmation: "password",
      role: :vendor,
      is_active: true
    )

    get "/api/v1/vendors/#{other_vendor.id}/income",
        headers: { "Authorization" => "Bearer #{token_for(vendor)}" },
        as: :json

    assert_response :forbidden
  end

  private

  def token_for(user)
    JsonWebToken.encode(user_id: user.id)
  end
end
