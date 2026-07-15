module Patreon
  # Shared writer for PatreonMembership rows. Every sync path (patron-side
  # identity sync, creator-side member poll, webhooks) funnels a JSON:API
  # member resource through here so status mapping, tier extraction, and
  # first_active_at semantics stay in one place.
  module MembershipUpsert
    STATUS_MAP = {
      "active_patron" => :active_patron,
      "declined_patron" => :declined_patron,
      "former_patron" => :former_patron
    }.freeze

    module_function

    # member: a JSON:API member hash ({ "id", "attributes", "relationships" }).
    def apply(user:, campaign:, member:, source:)
      attrs = member["attributes"] || {}
      tier_ids = member.dig("relationships", "currently_entitled_tiers", "data")&.map { |t| t["id"] } || []

      membership = PatreonMembership.find_or_initialize_by(user:, patreon_campaign: campaign)
      membership.assign_attributes(
        patreon_member_id: member["id"] || membership.patreon_member_id,
        patron_status: STATUS_MAP.fetch(attrs["patron_status"], :unknown),
        entitled_amount_cents: attrs["currently_entitled_amount_cents"].to_i,
        entitled_patreon_tier_ids: tier_ids,
        pledge_relationship_start: parse_time(attrs["pledge_relationship_start"]),
        synced_at: Time.current,
        source: source
      )
      # Our own first sighting of active support — set once, never overwritten,
      # so the back-catalog check survives Patreon resetting pledge start on
      # re-join.
      membership.first_active_at ||= Time.current if membership.patron_active_patron?
      membership.save!
      membership
    end

    # Demote a membership we know has ended (absent from a full sync, or a
    # members:delete webhook). Entitlements clear; join dates stay.
    def demote!(membership)
      membership.update!(
        patron_status: :former_patron,
        entitled_amount_cents: 0,
        entitled_patreon_tier_ids: [],
        synced_at: Time.current
      )
    end

    def parse_time(value)
      value.present? ? Time.zone.parse(value) : nil
    rescue ArgumentError
      nil
    end
  end
end
