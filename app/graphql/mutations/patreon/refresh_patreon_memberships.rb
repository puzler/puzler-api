module Mutations
  module Patreon
    class RefreshPatreonMemberships < Mutations::BaseMutation
      description "Re-sync which creators the current user supports on Patreon (patron-side " \
                  "sync). Throttled server-side; the cached result is used between refreshes."

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :user, Types::Objects::UserType, null: true, description: "The refreshed user"

      def resolve
        require_auth!

        identity = current_user.oauth_identities.find_by(provider: "patreon")
        return { user: nil, errors: [ "Patreon is not connected" ] } unless identity

        unless identity.scopes.to_s.split.include?("identity.memberships")
          return { user: nil, errors: [ "Reconnect Patreon to enable membership checks" ] }
        end

        ::Patreon::SyncPatronMemberships.call(current_user, source: :on_demand)
        { user: current_user, errors: [] }
      rescue ::Patreon::Token::RefreshFailed
        { user: nil, errors: [ "Patreon rejected our access. Reconnect Patreon to refresh it." ] }
      rescue ::Patreon::Client::RateLimited
        { user: nil, errors: [ "Patreon is rate limiting us right now. Try again in a few minutes." ] }
      rescue ::Patreon::Client::Error => e
        { user: nil, errors: [ "Patreon sync failed: #{e.message}" ] }
      end
    end
  end
end
