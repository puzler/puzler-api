FactoryBot.define do
  factory :folder do
    association :author, factory: :user
    sequence(:name) { |n| "Folder #{n}" }
    position { 0 }
  end
end
