# A creator's linked Patreon campaign — the anchor for patron-gated content.
# One per user (Patreon v2 allows one campaign per account). Synced from the
# Patreon API on link, on demand, and by the daily reconcile job.
class PatreonCampaign < ApplicationRecord
  belongs_to :user

  has_many :tiers, class_name: "PatreonTier", dependent: :destroy
  has_many :memberships, class_name: "PatreonMembership", dependent: :destroy

  encrypts :webhook_secret

  # active/token_stale keep creator features usable (stale = we serve cached
  # data and nag for a reconnect); disconnected/removed stop offering the
  # patrons_only visibility for NEW items but never touch existing content.
  enum :status, { active: 0, token_stale: 1, disconnected: 2, removed: 3 }, prefix: :status

  validates :patreon_id, presence: true, uniqueness: true
  validates :user_id, uniqueness: true

  # Whether the owner may gate new content to patrons. Stale tokens still count:
  # entitlement checks run off cached membership rows, so gating keeps working
  # while the creator sorts out a reconnect.
  def gating_available?
    status_active? || status_token_stale?
  end
end
