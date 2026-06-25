FactoryBot.define do
  factory :puzzle_play_participant do
    association :puzzle_play
    association :user
  end
end
