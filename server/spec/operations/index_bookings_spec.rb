require "rails_helper"

RSpec.describe Bookings::Index do
  it "loads bookings through policy scope and paginates them" do
    current_user = instance_double(User)
    scoped_relation = instance_double(ActiveRecord::Relation)
    records = [ instance_double(Booking) ]
    pagination = { page: 1, per_page: 20, total_count: 1, total_pages: 1 }

    allow(Pundit).to receive(:policy_scope!).with(current_user, Booking).and_return(scoped_relation)
    allow(scoped_relation).to receive(:includes).with(:show, :tickets, :coupon).and_return(scoped_relation)
    allow(scoped_relation).to receive(:order).with(booking_time: :desc).and_return(scoped_relation)
    allow(Pagination).to receive(:apply).with(scoped_relation, hash_including(page: 1, per_page: 20)).and_return([ records, pagination ])

    result = Bookings::Index.call(current_user: current_user, params: { page: 1, per_page: 20 })

    expect(result).to be_success
    expect(result[:records]).to eq(records)
    expect(result[:pagination]).to eq(pagination)
  end
end
