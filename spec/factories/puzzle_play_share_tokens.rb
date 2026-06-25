FactoryBot.define do
  factory :puzzle_play_share_token do
    association :puzzle_play
    association :created_by, factory: :user
    single_use { false }
  end
end
