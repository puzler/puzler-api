FactoryBot.define do
  factory :rating do
    association :puzzle, :published
    association :user
    stars { 4 }
    difficulty_vote { 3 }
  end
end
