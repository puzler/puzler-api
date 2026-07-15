module Types
  module Objects
    # The current user's Patreon standing, both sides at once: their own
    # campaign (creator), the creators they support (patron), and what their
    # stored OAuth grant covers. Only ever resolved self-only from UserType.
    class UserPatreonType < BaseObject
      description "The current user's Patreon link: campaign, memberships, and grant capabilities"

      field :campaign, PatreonCampaignType, null: true, method: :patreon_campaign,
        description: "The user's own campaign, when they are a creator"
      field :capabilities, PatreonCapabilitiesType, null: true,
        description: "Which Patreon features the stored OAuth grant covers; null when Patreon isn't linked"
      field :memberships, [ PatreonMembershipType ], null: false,
        description: "The creators this user supports on Patreon"

      def memberships
        object.patreon_memberships.includes(patreon_campaign: :user).order(:created_at)
      end

      # What the stored OAuth grant actually covers, so the client knows when
      # to prompt "reconnect to enable" (identities linked before the patron
      # feature carry narrower scopes).
      def capabilities
        identity = object.oauth_identities.find { |i| i.provider == "patreon" }
        return nil unless identity

        scopes = identity.scopes.to_s.split
        { memberships: scopes.include?("identity.memberships"), creator: scopes.include?("campaigns") }
      end
    end
  end
end
