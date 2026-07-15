FactoryBot.define do
  factory :patreon_tier do
    patreon_campaign
    sequence(:patreon_id) { |n| "tier-#{n}" }
    sequence(:title) { |n| "Tier #{n}" }
    amount_cents { 300 }
    published { true }

    trait :discarded do
      discarded_at { 1.day.ago }
    end
  end
end
