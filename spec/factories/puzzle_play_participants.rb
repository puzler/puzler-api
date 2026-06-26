FactoryBot.define do
  factory :puzzle_play_participant do
    association :puzzle_play
    association :user

    trait :guest do
      user { nil }
      sequence(:guest_token) { |n| "guest-token-#{n}" }
    end
  end
end
