require "rails_helper"

RSpec.describe Theatres::Create do
  it "creates a theatre for the current vendor using an existing city" do
    vendor = create(:user, :vendor)
    city = create(:city)

    result = Theatres::Create.call(
      current_user: vendor,
      params: {
        city_id: city.id,
        name: "Test Theatre",
        building_name: "Mall Plaza",
        street_address: "Main Street",
        pincode: "400001"
      }
    )

    expect(result).to be_success
    theatre = result[:model]
    expect(theatre.name).to eq("Test Theatre")
    expect(theatre.vendor).to eq(vendor)
    expect(theatre.city).to eq(city)
  end
end
