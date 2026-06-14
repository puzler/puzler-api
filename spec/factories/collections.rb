FactoryBot.define do
  factory :collection do
    association :author, factory: :user
    sequence(:title) { |n| "Collection #{n}" }
    visibility { :private }
    mode { :unordered }
  end
end
