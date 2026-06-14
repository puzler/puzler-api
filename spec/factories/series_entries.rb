FactoryBot.define do
  factory :series_entry do
    association :series
    association :entryable, factory: :puzzle
    sequence(:position) { |n| n }
  end
end
