# Which visibility values a user may SET on their content. The base four are
# universal; patrons_only unlocks only for creators with a live (or merely
# token-stale) Patreon campaign. subscribers_only stays unoffered (stubbed).
# Existing items keep whatever visibility they have if the author's creator
# status lapses — this gates new selections, never content.
module SelectableVisibilities
  BASE = %w[private unlisted public containers_only].freeze
  PATRON = "patrons_only".freeze

  def self.for(user)
    return BASE unless user&.patreon_campaign&.gating_available?

    BASE + [ PATRON ]
  end

  def self.allowed?(user, visibility)
    self.for(user).include?(visibility)
  end
end
