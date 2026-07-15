# A reward tier on a creator's Patreon campaign, mirrored from the API. Tiers
# that vanish from Patreon are discarded (soft delete), not destroyed: patron
# gates reference them and the min-tier amount fallback needs the recorded
# price even after deletion.
class PatreonTier < ApplicationRecord
  belongs_to :patreon_campaign

  validates :patreon_id, presence: true, uniqueness: { scope: :patreon_campaign_id }
  validates :title, presence: true
  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :kept, -> { where(discarded_at: nil) }
  scope :by_amount, -> { order(:amount_cents) }

  def discarded?
    discarded_at.present?
  end

  def discard!
    update!(discarded_at: Time.current) unless discarded?
  end

  def undiscard!
    update!(discarded_at: nil) if discarded?
  end
end
