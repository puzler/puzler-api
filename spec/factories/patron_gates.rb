FactoryBot.define do
  factory :patron_gate do
    association :gateable, factory: :puzzle
    mode { :min_tier }
    min_tier { nil }
  end
end
