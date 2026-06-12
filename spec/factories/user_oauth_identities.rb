FactoryBot.define do
  factory :user_oauth_identity do
    user
    provider { "google" }
    sequence(:uid) { |n| "uid-#{n}" }
    access_token { "access-token" }
    refresh_token { "refresh-token" }

    trait :patreon do
      provider { "patreon" }
    end
  end
end
