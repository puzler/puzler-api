FactoryBot.define do
  factory :story_page do
    association :author, factory: :user
    sequence(:title) { |n| "Chapter #{n}" }
    body_html { "<p>Once upon a time.</p>" }
  end
end
