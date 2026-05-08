FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "Tag #{n}" }
    # slug is auto-generated from name via before_validation on the model
  end
end
