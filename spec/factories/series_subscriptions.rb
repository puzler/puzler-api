FactoryBot.define do
  factory :series_subscription do
    association :series
    association :user
  end
end
