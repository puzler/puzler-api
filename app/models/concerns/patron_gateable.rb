# Shared patron-gating plumbing for Puzzle and Collection: the lazy scheduled
# release scope, patron preloads, and the two archive/feed listing scopes.
#
# patron_listed_for(user): everything patrons_only the viewer should SEE LISTED
#   — items they can open, plus locked upsell teasers from campaigns they
#   actively support (only where the creator left teasers on, and never when
#   the viewer opted out of teasers). Campaign-granularity where possible so
#   pagination stays pure SQL.
# patron_satisfiable_ids(user): the subquery of items whose gate the viewer's
#   cached membership actually PASSES — PatronAccess#satisfies? expressed in
#   SQL (kept in parity by spec).
module PatronGateable
  extend ActiveSupport::Concern

  included do
    has_one :patron_gate, as: :gateable, dependent: :destroy

    # Scheduled release, lazily evaluated on read (like CollectionEntry): nil
    # or past = released, future = invisible to non-authors until then.
    scope :released, -> { where("#{table_name}.released_at IS NULL OR #{table_name}.released_at <= ?", Time.current) }
    # Everything patron checks need in one preload: campaign via the author,
    # gate with its referenced tiers.
    scope :with_patron_preload, -> { includes({ author: :patreon_campaign }, patron_gate: [ :min_tier, :tiers ]) }
  end

  # Scheduled release check (lazy).
  def released?
    released_at.nil? || released_at <= Time.current
  end

  class_methods do
    # Released patrons_only items, published where the model has a lifecycle.
    def patron_base
      base = where(visibility: :patrons_only).released
      base = base.where(status: :published) if column_names.include?("status")
      base
    end

    def patron_listed_for(user)
      return none unless user

      satisfiable = patron_base.where(id: patron_satisfiable_ids(user))
      return satisfiable if user.hide_patron_teasers?

      # Locked teaser cards list only for campaigns the viewer actively
      # supports AND whose creator kept teasers on; accessible items always
      # list (a teasers-off creator still serves their actual patrons).
      teaser_author_ids = PatreonCampaign.where(teasers_enabled: true)
        .joins(:memberships)
        .where(patreon_memberships: {
          user_id: user.id,
          patron_status: PatreonMembership.patron_statuses[:active_patron]
        })
        .select(:user_id)

      patron_base.where(author_id: teaser_author_ids)
        .or(patron_base.where(id: patron_satisfiable_ids(user)))
    end

    # PatronAccess#satisfies? in SQL. Selects only ids so callers can embed it
    # as a plain `where(id: ...)` subquery (keeps outer relations `.or`-compatible).
    def patron_satisfiable_ids(user)
      active = PatreonMembership.patron_statuses[:active_patron]
      modes = PatronGate.modes

      patron_base
        .joins(author: :patreon_campaign)
        .joins(sanitize_sql_array([
          "INNER JOIN patreon_memberships pm ON pm.patreon_campaign_id = patreon_campaigns.id AND pm.user_id = ?",
          user.id
        ]))
        .joins(sanitize_sql_array([
          "LEFT JOIN patron_gates pg ON pg.gateable_type = ? " \
          "AND pg.gateable_id = #{connection.quote_table_name(table_name)}.id",
          name
        ]))
        .joins("LEFT JOIN patreon_tiers min_tier ON min_tier.id = pg.min_tier_id")
        .where("pm.patron_status = ?", active)
        .where(<<~SQL.squish, modes[:min_tier], modes[:tier_list], modes[:min_amount])
          CASE
            WHEN pg.id IS NULL OR (pg.mode = ? AND pg.min_tier_id IS NULL) THEN
              pm.entitled_amount_cents > 0 OR COALESCE(array_length(pm.entitled_patreon_tier_ids, 1), 0) > 0
            WHEN pg.mode = ? THEN
              EXISTS (
                SELECT 1 FROM patron_gate_tiers pgt
                JOIN patreon_tiers t ON t.id = pgt.patreon_tier_id
                WHERE pgt.patron_gate_id = pg.id
                  AND t.patreon_id = ANY (pm.entitled_patreon_tier_ids)
              )
            WHEN pg.mode = ? THEN pm.entitled_amount_cents >= pg.min_amount_cents
            ELSE
              min_tier.patreon_id = ANY (pm.entitled_patreon_tier_ids)
                OR pm.entitled_amount_cents >= min_tier.amount_cents
          END
        SQL
        .where(<<~SQL.squish)
          pg.id IS NULL OR pg.patrons_since_release = FALSE
            OR LEAST(pm.pledge_relationship_start, pm.first_active_at)
              <= COALESCE(#{connection.quote_table_name(table_name)}.released_at,
                          #{connection.quote_table_name(table_name)}.#{connection.quote_column_name(patron_release_fallback_column)})
        SQL
        .select(:id)
    end
  end
end
