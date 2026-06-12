module Types
  module Objects
    # Note: the GraphQL name must not end in "Connection" — graphql-ruby would
    # infer a Relay connection type and demand pagination arguments.
    class OauthIdentityType < BaseObject
      description "A linked OAuth provider account"

      field :created_at, GraphQL::Types::ISO8601DateTime, null: false,
        description: "When this provider was connected"
      field :provider, String, null: false, description: "Provider name: google or patreon"
    end
  end
end
