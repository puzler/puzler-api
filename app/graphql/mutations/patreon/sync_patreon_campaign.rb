module Mutations
  module Patreon
    class SyncPatreonCampaign < Mutations::BaseMutation
      description "Re-mirror the current user's Patreon campaign, tiers, and webhook now " \
                  "(creator-side sync)"

      field :campaign, Types::Objects::PatreonCampaignType, null: true,
        description: "The refreshed campaign; null when the user isn't a Patreon creator"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve
        require_auth!

        identity = current_user.oauth_identities.find_by(provider: "patreon")
        return { campaign: nil, errors: [ "Patreon is not connected" ] } unless identity

        unless identity.scopes.to_s.split.include?("campaigns")
          return { campaign: nil, errors: [ "Reconnect Patreon with creator access to sync your campaign" ] }
        end

        campaign = ::Patreon::SyncCreatorCampaign.call(current_user)
        if campaign.nil? && current_user.patreon_campaign&.status_token_stale?
          return { campaign: current_user.patreon_campaign,
                   errors: [ "Patreon rejected our access. Reconnect Patreon to refresh it." ] }
        end

        { campaign:, errors: [] }
      rescue ::Patreon::Client::Error => e
        { campaign: nil, errors: [ "Patreon sync failed: #{e.message}" ] }
      end
    end
  end
end
