FactoryBot.define do
  factory :collection_solve_time do
    association :collection
    association :puzzle
    association :user
    seconds { 30 }
  end
end
