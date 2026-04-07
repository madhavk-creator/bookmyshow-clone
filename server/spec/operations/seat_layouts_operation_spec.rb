require "rails_helper"

RSpec.describe SeatLayouts::Show do
  it "loads a published layout for guest users" do
    layout = create(:seat_layout, :published)

    result = SeatLayouts::Show.call(
      current_user: nil,
      params: { theatre_id: layout.screen.theatre_id, screen_id: layout.screen_id, id: layout.id }
    )

    expect(result).to be_success
    expect(result[:model]).to eq(layout)
  end

  it "fails when screen does not belong to theatre" do
    layout = create(:seat_layout, :published)
    other_theatre = create(:theatre)

    result = SeatLayouts::Show.call(
      current_user: nil,
      params: { theatre_id: other_theatre.id, screen_id: layout.screen_id, id: layout.id }
    )

    expect(result).not_to be_success
    expect(result[:errors]).to eq(screen: [ "Screen not found" ])
  end
end

RSpec.describe SeatLayouts::Update do
  it "updates a draft layout for the owning vendor" do
    vendor = create(:user, :vendor)
    theatre = create(:theatre, vendor: vendor)
    screen = create(:screen, theatre: theatre)
    layout = create(:seat_layout, screen: screen, name: "Old Layout")

    result = SeatLayouts::Update.call(
      current_user: vendor,
      params: {
        theatre_id: theatre.id,
        screen_id: screen.id,
        id: layout.id,
        name: "Updated Layout"
      }
    )

    expect(result).to be_success
    expect(result[:model].reload.name).to eq("Updated Layout")
  end

  it "fails authorization for a different vendor" do
    owner = create(:user, :vendor)
    other_vendor = create(:user, :vendor)
    theatre = create(:theatre, vendor: owner)
    screen = create(:screen, theatre: theatre)
    layout = create(:seat_layout, screen: screen)

    result = SeatLayouts::Update.call(
      current_user: other_vendor,
      params: {
        theatre_id: theatre.id,
        screen_id: screen.id,
        id: layout.id,
        name: "Blocked Update"
      }
    )

    expect(result).not_to be_success
    expect(result[:errors]).to eq(base: [ "Not authorized to update this layout" ])
  end
end
