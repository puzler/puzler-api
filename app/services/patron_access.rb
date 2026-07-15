# Per-request patron entitlement checker. Loads the viewer's Patreon
# memberships once (memoize an instance in GraphQL context and pass it to
# viewable_by? from list paths) and answers whether a patrons_only puzzle or
# collection is unlocked for them, or why not.
#
# All answers come from CACHED membership rows (synced via OAuth link,
# webhooks, the daily reconcile, and throttled on-demand checks) — never from
# live API calls; freshness is the sync layer's job.
class PatronAccess
  def initialize(user)
    @user = user
  end

  # Does the viewer pass `gateable`'s patron gate? False for guests, unlinked
  # users, non-patrons, and lapsed/declined patrons. No gate row (or a min_tier
  # gate whose tier is unset) is the default gate: any active patron with a
  # nonzero pledge or any entitled tier.
  def satisfies?(gateable)
    campaign = campaign_for(gateable)
    return false unless campaign

    membership = memberships[campaign.id]
    return false unless membership&.patron_active_patron?

    gate = gateable.patron_gate
    meets_gate?(membership, gate) && meets_back_catalog?(membership, gate, gateable)
  end

  # Why the viewer is locked out — powers the teaser panel copy. Only
  # meaningful when satisfies? returned false.
  def locked_reason(gateable)
    campaign = campaign_for(gateable)
    return :creator_unavailable if campaign.nil? || campaign.status_removed?
    return :not_linked unless @user && patreon_linked?

    membership = memberships[campaign.id]
    return :not_patron unless membership
    return :declined if membership.patron_declined_patron?
    return :not_patron unless membership.patron_active_patron?

    gate = gateable.patron_gate
    return :insufficient_tier unless meets_gate?(membership, gate)

    :joined_after_release
  end

  private

  def campaign_for(gateable)
    gateable.author&.patreon_campaign
  end

  # All of the viewer's memberships (any status — locked_reason needs declined
  # and former too), one query, indexed by campaign. Queried directly rather
  # than through the user's association so a mid-request sync (the on-demand
  # freshness path re-checks right after updating rows) is never masked by
  # Rails' association cache on a long-lived user instance.
  def memberships
    @memberships ||=
      if @user
        PatreonMembership.where(user_id: @user.id).index_by(&:patreon_campaign_id)
      else
        {}
      end
  end

  def patreon_linked?
    return @patreon_linked if defined?(@patreon_linked)

    @patreon_linked = @user.oauth_identities.exists?(provider: "patreon")
  end

  def meets_gate?(membership, gate)
    case gate&.mode
    when nil
      default_gate?(membership)
    when "min_tier"
      tier = gate.min_tier
      return default_gate?(membership) unless tier

      # Entitled to the tier itself, or pledging at least its price — the
      # amount fallback covers active patrons whose entitled-tier list is
      # empty (custom pledges, deleted tiers).
      membership.entitled_patreon_tier_ids.include?(tier.patreon_id) ||
        membership.entitled_amount_cents >= tier.amount_cents
    when "tier_list"
      (membership.entitled_patreon_tier_ids & gate.tiers.map(&:patreon_id)).any?
    when "min_amount"
      membership.entitled_amount_cents >= gate.min_amount_cents.to_i
    end
  end

  def default_gate?(membership)
    membership.entitled_amount_cents.positive? || membership.entitled_patreon_tier_ids.any?
  end

  # Back-catalog lock: the membership must predate the item's release moment.
  # supporting_since uses the earlier of Patreon's pledge start and our own
  # first sighting, so returning long-time patrons keep access.
  def meets_back_catalog?(membership, gate, gateable)
    return true unless gate&.patrons_since_release?

    since = membership.supporting_since
    release = gateable.effective_release_at
    since.present? && release.present? && since <= release
  end
end
