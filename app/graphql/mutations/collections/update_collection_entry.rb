module Mutations
  module Collections
    # Author-side per-entry hunt gates, all opt-in: a codeword the solver must
    # enter, hidden (invisible until the codeword is entered), and finale
    # (unlocks when every other puzzle is solved). Omitted gate fields leave
    # the setting untouched; an empty codeword clears the gate.
    class UpdateCollectionEntry < Mutations::BaseMutation
      description "Update an entry's hunt gates: codeword, hidden, finale"

      argument :collection_id, ID, required: true, description: "The collection"
      argument :entry_id, ID, required: true, description: "Entry to update"
      argument :gates, Types::InputObjects::CollectionEntryGatesInput, required: true,
        description: "Gate settings to change"

      field :collection, Types::Objects::CollectionType, null: true, description: "The updated collection"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(collection_id:, entry_id:, gates:)
        collection = require_owned!(:collections, "Collection", id: collection_id)
        entry = collection.entries.find_by(id: entry_id)
        return { collection: nil, errors: [ "Entry not found" ] } unless entry

        settings = gates.to_h
        entry.codeword = settings[:codeword] if settings.key?(:codeword)
        entry.hidden = settings[:hidden] if settings.key?(:hidden)
        entry.finale = settings[:finale] if settings.key?(:finale)

        if entry.save
          { collection: collection.reload, errors: [] }
        else
          { collection: nil, errors: entry.errors.full_messages }
        end
      end
    end
  end
end
