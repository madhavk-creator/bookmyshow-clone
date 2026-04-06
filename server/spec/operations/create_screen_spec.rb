require "rails_helper"

RSpec.describe Screens::Create do
  it "creates a screen with selected format capabilities for the theatre owner" do
    vendor = build_user(role: :vendor, email_prefix: "vendor", phone: "9876543210")
    city = build_city
    theatre = build_theatre_for(vendor: vendor, city: city)
    format_one = Format.create!(name: "IMAX#{SecureRandom.hex(2)}", code: "imax#{SecureRandom.hex(2)}")
    format_two = Format.create!(name: "FOURDX#{SecureRandom.hex(2)}", code: "4dx#{SecureRandom.hex(2)}")

    result = Screens::Create.call(
      current_user: vendor,
      params: {
        theatre_id: theatre.id,
        name: "Screen 1",
        status: "active",
        total_rows: 10,
        total_columns: 12,
        format_ids: [ format_one.id, format_two.id ]
      }
    )

    expect(result).to be_success
    screen = result[:model]
    expect(screen.name).to eq("Screen 1")
    expect(screen.theatre).to eq(theatre)
    expect(screen.formats.pluck(:id)).to match_array([ format_one.id, format_two.id ])
  end
end
