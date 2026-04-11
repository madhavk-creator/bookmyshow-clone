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

  it "ignores attempts to change the layout dimensions directly" do
    vendor = create(:user, :vendor)
    theatre = create(:theatre, vendor: vendor)
    screen = create(:screen, theatre: theatre, total_rows: 10, total_columns: 12)
    layout = create(:seat_layout, screen: screen, total_rows: 10, total_columns: 12)

    result = SeatLayouts::Update.call(
      current_user: vendor,
      params: {
        theatre_id: theatre.id,
        screen_id: screen.id,
        id: layout.id,
        total_rows: 20,
        total_columns: 25
      }
    )

    expect(result).to be_success
    expect(result[:model].reload.total_rows).to eq(10)
    expect(result[:model].total_columns).to eq(12)
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

RSpec.describe SeatLayouts::Create do
  it "derives layout dimensions from the screen" do
    vendor = create(:user, :vendor)
    theatre = create(:theatre, vendor: vendor)
    screen = create(:screen, theatre: theatre, total_rows: 10, total_columns: 12)

    result = described_class.call(
      current_user: vendor,
      params: {
        theatre_id: theatre.id,
        screen_id: screen.id,
        name: "Main Layout",
        total_rows: 20,
        total_columns: 25
      }
    )

    expect(result).to be_success
    expect(result[:model].total_rows).to eq(10)
    expect(result[:model].total_columns).to eq(12)
  end
end

RSpec.describe SeatLayouts::SyncSeats do
  it "rejects seats outside the layout grid" do
    vendor = create(:user, :vendor)
    theatre = create(:theatre, vendor: vendor)
    screen = create(:screen, theatre: theatre, total_rows: 2, total_columns: 2)
    layout = create(:seat_layout, screen: screen)
    section = create(:seat_section, seat_layout: layout)

    result = described_class.call(
      current_user: vendor,
      params: {
        theatre_id: theatre.id,
        screen_id: screen.id,
        id: layout.id,
        seats: [
          {
            row_label: "A",
            seat_number: 1,
            grid_row: 2,
            grid_column: 0,
            seat_section_id: section.id,
            seat_kind: "standard",
            x_span: 1,
            y_span: 1,
            is_accessible: false,
            is_active: true
          }
        ]
      }
    )

    expect(result).not_to be_success
    expect(result[:errors]).to include(grid_row: [ "Grid row must be within the layout row count" ])
  end
end

RSpec.describe SeatLayouts::Publish do
  it "archives an older published layout before publishing a new draft layout" do
    vendor = create(:user, :vendor)
    theatre = create(:theatre, vendor: vendor)
    screen = create(:screen, theatre: theatre)
    old_layout = create(:seat_layout, :published, screen: screen)
    new_layout = create(:seat_layout, screen: screen)
    section = create(:seat_section, seat_layout: new_layout)
    create(:seat, seat_layout: new_layout, seat_section: section)

    result = described_class.call(
      current_user: vendor,
      params: { theatre_id: theatre.id, screen_id: screen.id, id: new_layout.id }
    )

    expect(result).to be_success
    expect(old_layout.reload.status).to eq("archived")
    expect(new_layout.reload.status).to eq("published")
  end

  it "fails when the currently published layout still has upcoming scheduled shows" do
    vendor = create(:user, :vendor)
    theatre = create(:theatre, vendor: vendor)
    screen = create(:screen, theatre: theatre)
    old_layout = create(:seat_layout, :published, screen: screen)
    create(:show, :bookable, screen: screen, seat_layout: old_layout)

    new_layout = create(:seat_layout, screen: screen)
    section = create(:seat_section, seat_layout: new_layout)
    create(:seat, seat_layout: new_layout, seat_section: section)

    result = described_class.call(
      current_user: vendor,
      params: { theatre_id: theatre.id, screen_id: screen.id, id: new_layout.id }
    )

    expect(result).not_to be_success
    expect(result[:errors]).to eq(
      base: [ "Cannot publish this layout while another published layout has upcoming scheduled shows" ]
    )
    expect(old_layout.reload.status).to eq("published")
    expect(new_layout.reload.status).to eq("draft")
  end
end
