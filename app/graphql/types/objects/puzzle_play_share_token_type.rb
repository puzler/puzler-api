module Types
  module Objects
    class PuzzlePlayShareTokenType < BaseObject
      description "A short, unguessable capability to join a shared play session"

      field :consumed, Boolean, null: false, description: "True once a single-use token has been claimed"
      field :id, ID, null: false, description: "Unique share-token id"
      field :single_use, Boolean, null: false, description: "Locks to the first joiner when true"
      field :token, String, null: false, description: "The short share token"

      def consumed
        object.consumed_by_id.present?
      end
    end
  end
end
