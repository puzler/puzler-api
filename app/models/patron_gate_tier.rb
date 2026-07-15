# Join row for tier_list gates: one per selected tier.
class PatronGateTier < ApplicationRecord
  belongs_to :patron_gate
  belongs_to :patreon_tier

  validates :patreon_tier_id, uniqueness: { scope: :patron_gate_id }
end
