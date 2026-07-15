# A linked Puzler user's membership in a Puzler creator's Patreon campaign —
# the cached entitlement that patron gates check. Rows exist only for users who
# linked Patreon; they are updated by OAuth-link sync, webhooks, the daily
# creator-side reconcile, and throttled on-demand checks. Rows are never
# deleted: lapsed patrons become former_patron, and the history backs the
# back-catalog (patrons-since-release) check.
class PatreonMembership < ApplicationRecord
  belongs_to :user
  belongs_to :patreon_campaign

  enum :patron_status, { unknown: 0, active_patron: 1, declined_patron: 2, former_patron: 3 },
    prefix: :patron

  enum :source, { oauth: 0, webhook: 1, creator_poll: 2, on_demand: 3 }, prefix: :source

  validates :user_id, uniqueness: { scope: :patreon_campaign_id }
  validates :entitled_amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(patron_status: :active_patron) }

  # The earliest moment we can credit this member's support from: Patreon's
  # pledge_relationship_start resets when a lapsed patron re-joins, so our own
  # first_active_at (set once, never overwritten) covers returning patrons.
  def supporting_since
    [ pledge_relationship_start, first_active_at ].compact.min
  end
end
