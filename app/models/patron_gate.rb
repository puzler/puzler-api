# Per-item patron gate config for patrons_only puzzles/collections. Absence of
# a row is the default gate: any active patron of the author's campaign (any
# entitled tier, or any pledge amount above zero) — so flipping visibility works
# before the author configures anything.
class PatronGate < ApplicationRecord
  belongs_to :gateable, polymorphic: true
  belongs_to :min_tier, class_name: "PatreonTier", optional: true

  has_many :gate_tiers, class_name: "PatronGateTier", dependent: :destroy
  has_many :tiers, through: :gate_tiers, source: :patreon_tier

  # min_tier: entitled to the tier or any higher-priced one (pledge-amount
  # fallback covers custom pledges whose entitled-tier list is empty).
  # tier_list: entitled to ANY of the selected tiers (strict; no fallback).
  # min_amount: pledge amount alone.
  enum :mode, { min_tier: 0, tier_list: 1, min_amount: 2 }, prefix: :mode

  validates :gateable_type, inclusion: { in: %w[Puzzle Collection] }
  validates :min_amount_cents, numericality: { only_integer: true, greater_than: 0 },
    if: :mode_min_amount?
  validate :tiers_belong_to_author_campaign
  validate :tier_list_has_tiers

  private

  # Every referenced tier must belong to the gateable author's own campaign —
  # a gate must never point at some other creator's tiers.
  def tiers_belong_to_author_campaign
    campaign = gateable&.author&.patreon_campaign
    referenced = [ min_tier, *tiers ].compact
    return if referenced.empty?

    unless campaign && referenced.all? { |tier| tier.patreon_campaign_id == campaign.id }
      errors.add(:base, "tiers must belong to your own Patreon campaign")
    end
  end

  def tier_list_has_tiers
    errors.add(:base, "select at least one tier") if mode_tier_list? && gate_tiers.empty? && tiers.empty?
  end
end
