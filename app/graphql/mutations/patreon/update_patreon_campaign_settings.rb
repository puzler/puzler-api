module Mutations
  module Patreon
    class UpdatePatreonCampaignSettings < Mutations::BaseMutation
      description "Update the current user's Patreon campaign settings on Puzler (e.g. whether " \
                  "non-patrons see locked previews of gated content)"

      argument :teasers_enabled, Boolean, required: true,
        description: "Whether non-patrons see locked previews (teasers) of this campaign's gated content"

      field :campaign, Types::Objects::PatreonCampaignType, null: true, description: "The updated campaign"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(teasers_enabled:)
        require_auth!

        campaign = current_user.patreon_campaign
        return { campaign: nil, errors: [ "No linked Patreon campaign" ] } unless campaign

        if campaign.update(teasers_enabled:)
          { campaign:, errors: [] }
        else
          { campaign: nil, errors: campaign.errors.full_messages }
        end
      end
    end
  end
end
