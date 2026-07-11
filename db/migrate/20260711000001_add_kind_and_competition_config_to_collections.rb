# Collections gain a kind: basic (plain list), hunt (the rich-collections
# experience), or competition (solver-timed, server-refereed contest). The
# competition config rides along: author-set time limit, submission policy,
# scoring knobs, and the enforced player-settings map (settingKey => bool;
# absent = solver's choice; the frontend owns the key list). Default 0 = basic
# for everything, existing collections included.
class AddKindAndCompetitionConfigToCollections < ActiveRecord::Migration[8.0]
  def change
    add_column :collections, :kind, :integer, default: 0, null: false
    add_column :collections, :time_limit_seconds, :integer
    add_column :collections, :submission_policy, :integer, default: 0, null: false
    add_column :collections, :penalty_points, :integer, default: 0, null: false
    add_column :collections, :bonus_points_per_minute, :integer, default: 0, null: false
    add_column :collections, :clamp_score_at_zero, :boolean, default: true, null: false
    add_column :collections, :enforced_settings, :jsonb, default: {}, null: false
    add_index :collections, :kind
  end
end
