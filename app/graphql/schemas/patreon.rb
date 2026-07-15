module Schemas
  module Patreon
    module Queries
      include Types::Interfaces::BaseInterface
      description "Patreon patron-content queries"
      graphql_name "PatreonQueries"

      field :patron_releases, [ Types::Unions::PatronReleaseType ], null: false,
        description: "Newest patron releases (puzzles and collections) from campaigns the " \
                     "viewer actively supports, newest first. Locked items list as teasers " \
                     "per the creator's and viewer's teaser settings."

      # The feed shares its inclusion semantics with the archive: both go
      # through patron_listed_for, so an item teased in one is teased in the
      # other. Lazily-released items appear the moment released_at passes —
      # nothing is scheduled, the scopes evaluate release on read.
      def patron_releases
        user = context[:current_user]
        return [] unless user

        puzzles = Puzzle.patron_listed_for(user).with_patron_preload.includes(:author, :tags).to_a
        collections = Collection.patron_listed_for(user).with_patron_preload.includes(:author).to_a

        (puzzles + collections)
          .sort_by { |item| item.effective_release_at || Time.zone.at(0) }
          .reverse
          .first(50)
      end
    end

    module Mutations
      include Types::Interfaces::BaseInterface
      description "Patreon link and campaign mutations"
      graphql_name "PatreonMutations"

      field :refresh_patreon_memberships, mutation: ::Mutations::Patreon::RefreshPatreonMemberships,
        description: "Re-sync which creators the current user supports on Patreon"
      field :sync_patreon_campaign, mutation: ::Mutations::Patreon::SyncPatreonCampaign,
        description: "Re-mirror the current user's Patreon campaign, tiers, and webhook"
      field :update_patreon_campaign_settings, mutation: ::Mutations::Patreon::UpdatePatreonCampaignSettings,
        description: "Update the current user's Puzler-side Patreon campaign settings"
    end
  end
end
