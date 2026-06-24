class UserTheme < ApplicationRecord
  belongs_to :user

  # Mirrors the frontend's BuiltInThemeId (utils/theme.ts). A user theme always records which
  # built-in it derived from, for provenance and "reset to default".
  BASE_PRESET_IDS = %w[classic light dark high_contrast].freeze

  # `uid` is the client-generated stable identity (see the migration); unique per user so the
  # same uid can exist for different users without collision.
  validates :uid, presence: true, uniqueness: { scope: :user_id }
  validates :name, presence: true, length: { maximum: 60 }
  validates :base_preset_id, inclusion: { in: BASE_PRESET_IDS }
  validates :schema_version, numericality: { only_integer: true, greater_than: 0 }
  validate :appearance_is_object
  validate :constraints_is_object

  private

  # The style maps are frontend-owned sparse objects; guard only that they are JSON objects
  # (not arrays/scalars), leaving key/value shape validation to the frontend normalizer.
  def appearance_is_object
    errors.add(:appearance, "must be an object") unless appearance.is_a?(Hash)
  end

  def constraints_is_object
    errors.add(:constraints, "must be an object") unless constraints.is_a?(Hash)
  end
end
