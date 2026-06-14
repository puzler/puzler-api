FactoryBot.define do
  factory :series do
    association :author, factory: :user
    sequence(:title) { |n| "Series #{n}" }
    visibility { :private }
  end
end
