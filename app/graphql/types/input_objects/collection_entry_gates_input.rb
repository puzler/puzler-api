module Types
  module InputObjects
    class CollectionEntryGatesInput < BaseInputObject
      description "Per-entry hunt gates; omitted fields are left untouched"

      argument :codeword, String, required: false,
        description: "Codeword required to open this entry; empty string clears it"
      argument :finale, Boolean, required: false,
        description: "Unlock only after every other puzzle in the collection is solved"
      argument :hidden, Boolean, required: false,
        description: "Hide the entry until its codeword is entered (requires a codeword)"
      argument :released_at, GraphQL::Types::ISO8601DateTime, required: false,
        description: "Scheduled release time; explicit null releases the entry now"
    end
  end
end
