module Types
  module Objects
    # A patron-facing reference to someone else's campaign: just enough to name
    # and link it. (PatreonCampaignType is the owner-facing mirror with sync
    # and webhook internals — never shown to patrons.)
    class PatreonCampaignRefType < BaseObject
      description "A supported Patreon campaign, as seen by a patron"

      field :creator_username, String, null: true,
        description: "The Puzler username of the campaign's creator"
      field :currency, String, null: true, description: "Campaign currency code"
      field :title, String, null: true, description: "Campaign name on Patreon"
      field :url, String, null: true, description: "The campaign's patreon.com page"

      def creator_username
        object.user.username
      end
    end
  end
end
