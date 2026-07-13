FactoryBot.define do
  factory :puzzle do
    association :author, factory: :user
    sequence(:title) { |n| "Test Puzzle #{n}" }
    description { "A test puzzle." }
    grid_rows { 9 }
    grid_cols { 9 }
    box_layout { nil }
    given_digits { { "r0c0" => 5, "r4c4" => 9 } }
    ruleset { {} }
    status { :draft }
    solve_count { 0 }
    favorite_count { 0 }

    trait :published do
      status { :published }
      visibility { :public }
      published_at { 1.day.ago }
    end

    trait :featured do
      status { :published }
      featured { true }
      visibility { :public }
      published_at { 1.day.ago }
    end

    trait :unlisted do
      status { :published }
      visibility { :unlisted }
      published_at { 1.day.ago }
    end

    trait :access_private do
      status { :published }
      visibility { :private }
      published_at { 1.day.ago }
    end

    trait :containers_only do
      status { :published }
      visibility { :containers_only }
      published_at { 1.day.ago }
    end
  end
end
