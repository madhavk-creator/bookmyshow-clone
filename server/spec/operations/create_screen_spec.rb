require "rails_helper"

RSpec.describe Screens::Create do
  it "creates a screen with selected format capabilities for the theatre owner" do
    vendor = create(:user, :vendor)
    theatre = create(:theatre, vendor: vendor)
    format_one = create(:format)
    format_two = create(:format, name: "FOURDX", code: "4dx")

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
