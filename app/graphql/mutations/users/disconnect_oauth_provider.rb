module Mutations
  module Users
    class DisconnectOauthProvider < Mutations::BaseMutation
      description "Remove a linked OAuth provider from the current user's account"

      argument :provider, String, required: true,
        description: "Provider to disconnect: google or patreon"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :user, Types::Objects::UserType, null: true,
        description: "The updated user"

      def resolve(provider:)
        require_auth!

        identity = current_user.oauth_identities.find_by(provider:)
        return { user: nil, errors: [ "#{provider.capitalize} is not connected" ] } unless identity

        unless current_user.password_set? || current_user.oauth_identities.where.not(provider:).exists?
          return { user: nil, errors: [ "You can't remove your last way to sign in. Set a password first." ] }
        end

        teardown_patreon! if provider == "patreon"
        identity.destroy!
        { user: current_user, errors: [] }
      end

      private

      # Unlinking Patreon: memberships go (we can no longer verify entitlement,
      # so patron access ends immediately); an owned campaign is only marked
      # disconnected — existing gated content stays gated on cached member data
      # and the author stops being offered the Patrons visibility for new items.
      # Webhook deletion is best-effort with the still-valid token.
      def teardown_patreon!
        current_user.patreon_memberships.destroy_all

        campaign = current_user.patreon_campaign
        return unless campaign

        if campaign.webhook_patreon_id.present?
          begin
            identity = current_user.oauth_identities.find_by(provider: "patreon")
            Patreon::Token.with_retry(identity) do |client|
              client.delete_webhook(campaign.webhook_patreon_id)
            end
            campaign.update!(webhook_patreon_id: nil, webhook_secret: nil, webhook_paused_at: nil)
          rescue Patreon::Token::RefreshFailed, Patreon::Client::Error
            nil
          end
        end
        campaign.update!(status: :disconnected)
      end
    end
  end
end
