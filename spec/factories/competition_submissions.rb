FactoryBot.define do
  factory :competition_submission do
    association :competition_run
    association :puzzle
    correct { true }
    submitted_at { Time.current }
  end
end
