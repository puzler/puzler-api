FactoryBot.define do
  factory :rating do
    association :puzzle, :published
    association :user
    stars { 4 }
    difficulty_vote { "medium" }
  end
end
