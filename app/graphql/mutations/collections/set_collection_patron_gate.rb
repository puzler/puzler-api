module Mutations
  module Collections
    class SetCollectionPatronGate < Mutations::BaseMutation
      include Mutations::AppliesPatronGate

      description "Configure who qualifies for a patrons-only collection; null gate resets to " \
                  "the default (any paying patron)"

      argument :gate, Types::InputObjects::PatronGateInput, required: false,
        description: "The gate configuration; omit/null to clear back to the default gate"
      argument :id, ID, required: true, description: "ID of the collection"

      field :collection, Types::Objects::CollectionType, null: true, description: "The updated collection"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(id:, gate: nil)
        collection = require_owned!(:collections, "Collection", id:)

        errors = apply_patron_gate(collection, gate)
        errors.empty? ? { collection:, errors: [] } : { collection: nil, errors: }
      end
    end
  end
end
