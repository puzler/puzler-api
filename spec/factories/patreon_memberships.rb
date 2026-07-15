FactoryBot.define do
  factory :patreon_membership do
    user
    patreon_campaign
    sequence(:patreon_member_id) { |n| "member-#{n}" }
    patron_status { :active_patron }
    entitled_amount_cents { 300 }
    entitled_patreon_tier_ids { [] }
    synced_at { Time.current }
    source { :oauth }

    trait :former do
      patron_status { :former_patron }
      entitled_amount_cents { 0 }
      entitled_patreon_tier_ids { [] }
    end

    trait :declined do
      patron_status { :declined_patron }
    end
  end
end
