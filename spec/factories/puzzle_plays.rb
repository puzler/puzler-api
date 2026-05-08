FactoryBot.define do
  factory :puzzle_play do
    association :puzzle, :published
    user { nil }
    cell_state { {} }
    started_at { Time.current }
    is_solved { false }
    time_elapsed_seconds { 0 }

    trait :with_user do
      association :user
    end

    trait :solved do
      is_solved { true }
      completed_at { Time.current }
      time_elapsed_seconds { 300 }
    end
  end
end
