require "rails_helper"

RSpec.describe Screens::Update do
  it "updates screen capabilities when no scheduled show depends on a removed format" do
    vendor = create(:user, :vendor)
    theatre = create(:theatre, vendor: vendor)
    screen = create(:screen, theatre: theatre)
    format_one = create(:format, code: "imax")
    format_two = create(:format, code: "2d")
    create(:screen_capability, screen: screen, format: format_one)
    create(:screen_capability, screen: screen, format: format_two)

    result = Screens::Update.call(
      current_user: vendor,
      params: {
        theatre_id: theatre.id,
        id: screen.id,
        format_ids: [ format_one.id ]
      }
    )

    expect(result).to be_success
    expect(screen.reload.formats.pluck(:id)).to eq([ format_one.id ])
  end

  it "blocks removing a format that still has a scheduled show on the screen" do
    vendor = create(:user, :vendor)
    theatre = create(:theatre, vendor: vendor)
    screen = create(:screen, theatre: theatre)
    format_one = create(:format, code: "imax")
    format_two = create(:format, code: "2d")
    create(:screen_capability, screen: screen, format: format_one)
    create(:screen_capability, screen: screen, format: format_two)

    movie = create(:movie)
    movie_language = create(:movie_language, movie: movie)
    movie_format = create(:movie_format, movie: movie, format: format_two)
    layout = create(:seat_layout, :published, screen: screen)
    create(
      :show,
      screen: screen,
      seat_layout: layout,
      movie: movie,
      movie_language: movie_language,
      movie_format: movie_format,
      status: :scheduled
    )

    result = Screens::Update.call(
      current_user: vendor,
      params: {
        theatre_id: theatre.id,
        id: screen.id,
        format_ids: [ format_one.id ]
      }
    )

    expect(result).not_to be_success
    expect(result[:errors]).to eq(
      format_ids: [ "Cannot remove formats with scheduled shows: 2d" ]
    )
    expect(screen.reload.formats.pluck(:id)).to match_array([ format_one.id, format_two.id ])
  end
end
