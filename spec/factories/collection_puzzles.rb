FactoryBot.define do
  factory :collection_puzzle do
    association :collection
    association :puzzle
    sequence(:position)
  end
end
