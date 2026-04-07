FactoryBot.define do
  factory :theatre do
    association :vendor, factory: [ :user, :vendor ]
    city
    sequence(:name) { |n| "Theatre #{n}" }
    building_name { "Mall Plaza" }
    street_address { "Main Street" }
    pincode { "400001" }
  end

  factory :screen do
    theatre
    sequence(:name) { |n| "Screen #{n}" }
    total_rows { 5 }
    total_columns { 5 }
    total_seats { 25 }
    status { :active }
  end
end
