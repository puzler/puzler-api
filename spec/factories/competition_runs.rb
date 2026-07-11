FactoryBot.define do
  factory :competition_run do
    association :collection
    association :user
    started_at { Time.current }
    deadline { 30.minutes.from_now }

    trait :expired do
      started_at { 1.hour.ago }
      deadline { 10.minutes.ago }
    end
  end
end
