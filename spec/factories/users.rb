FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    sequence(:email)    { |n| "user#{n}@example.com" }
    password { "password123" }
    role { :user }

    trait :admin do
      role { :admin }
    end
  end
end
