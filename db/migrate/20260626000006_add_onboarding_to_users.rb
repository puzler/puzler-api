class AddOnboardingToUsers < ActiveRecord::Migration[8.1]
  def change
    # Growing, schemaless map of tour keys the user has completed.
    add_column :users, :onboarding_seen, :jsonb, null: false, default: {}
    # First-class scalar toggle for turning guided walkthroughs off entirely.
    add_column :users, :onboarding_disabled, :boolean, null: false, default: false
  end
end
