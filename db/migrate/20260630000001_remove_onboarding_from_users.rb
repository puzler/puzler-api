class RemoveOnboardingFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :onboarding_seen, :jsonb, null: false, default: {}
    remove_column :users, :onboarding_disabled, :boolean, null: false, default: false
  end
end
