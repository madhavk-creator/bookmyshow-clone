FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "person#{n}@example.com" }
    sequence(:name) { |n| "Test User #{n}" }
    phone { "9876543210" }
    password { "Password123!" }
    password_confirmation { password }
    role { :user }
    is_active { true }

    trait :vendor do
      role { :vendor }
      sequence(:name) { |n| "Vendor User #{n}" }
    end

    trait :admin do
      role { :admin }
      sequence(:name) { |n| "Admin User #{n}" }
    end

    trait :inactive do
      is_active { false }
    end
  end
end
