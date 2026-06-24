FactoryBot.define do
  factory :user_theme do
    user
    sequence(:uid) { |n| "theme-#{n}" }
    sequence(:name) { |n| "Theme #{n}" }
    base_preset_id { "classic" }
    schema_version { 1 }
    appearance { { "chrome" => {}, "grid" => {} } }
    constraints { {} }
  end
end
