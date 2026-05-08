FactoryBot.define do
  factory :user_oauth_identity do
    user { nil }
    provider { "MyString" }
    uid { "MyString" }
    access_token { "MyText" }
    refresh_token { "MyText" }
  end
end
