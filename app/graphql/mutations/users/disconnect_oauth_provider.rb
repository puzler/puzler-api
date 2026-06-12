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

        identity.destroy!
        { user: current_user, errors: [] }
      end
    end
  end
end
