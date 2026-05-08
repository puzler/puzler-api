FactoryBot.define do
  factory :comment do
    association :puzzle, :published
    association :user
    body { "Great puzzle!" }
    parent { nil }

    trait :reply do
      association :parent, factory: :comment
    end
  end
end
