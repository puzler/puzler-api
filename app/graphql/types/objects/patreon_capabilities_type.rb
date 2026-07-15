module Types
  module Objects
    # Which Patreon features the user's stored OAuth grant covers. Identities
    # linked before the patron feature carry narrower scopes; false here means
    # "reconnect Patreon to enable".
    class PatreonCapabilitiesType < BaseObject
      description "Which Patreon features the current user's OAuth grant covers"

      field :creator, Boolean, null: false,
        description: "Whether the grant can read the user's own campaign (creator features)"
      field :memberships, Boolean, null: false,
        description: "Whether the grant can read the user's memberships (patron features)"
    end
  end
end
