FactoryBot.define do
  factory :favorite do
    association :puzzle, :published
    association :user
  end
end
