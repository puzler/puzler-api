module Mutations
  module Collections
    # A solver's codeword guess, checked against every gated entry in the
    # collection (one input box, classic hunt style). Matching entries unlock
    # permanently for this actor (user account or guest token). Case and
    # surrounding whitespace are ignored.
    class SubmitCollectionCodeword < Mutations::BaseMutation
      description "Try a codeword against a collection's gated entries"

      argument :collection_id, ID, required: true, description: "The collection"
      argument :guess, String, required: true, description: "The codeword to try"
      argument :share_token, String, required: false,
        description: "Share token, when the collection was reached by link"

      field :collection, Types::Objects::CollectionType, null: true,
        description: "The collection with the viewer's refreshed lock state"
      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :matched, Boolean, null: false, description: "Whether the guess opened anything"

      def resolve(collection_id:, guess:, share_token: nil)
        require_actor!
        actor = current_actor
        collection = Collection.find_by(id: collection_id)
        unless collection&.viewable_by?(current_user, share_token: share_token)
          return { matched: false, collection: nil, errors: [ "Collection not found" ] }
        end

        matches = collection.entries.where.not(codeword_digest: nil)
                            .select { |entry| entry.codeword_matches?(guess) }
        matches.each do |entry|
          entry.unlocks.find_or_create_by!(actor.owner_attrs)
        end

        { matched: matches.any?, collection: collection.reload, errors: [] }
      end
    end
  end
end
