FactoryBot.define do
  factory :patreon_campaign do
    user
    sequence(:patreon_id) { |n| "campaign-#{n}" }
    title { "Test Campaign" }
    url { "https://www.patreon.com/testcampaign" }
    currency { "USD" }
    status { :active }
    teasers_enabled { true }

    trait :token_stale do
      status { :token_stale }
    end

    trait :removed do
      status { :removed }
    end

    trait :no_teasers do
      teasers_enabled { false }
    end
  end
end
