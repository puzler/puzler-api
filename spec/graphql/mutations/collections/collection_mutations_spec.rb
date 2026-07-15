require "rails_helper"

RSpec.describe "Collection mutations", type: :graphql do
  let(:user) { create(:user) }

  def gql(mutation, vars, ctx = nil)
    execute_query(mutation, variables: vars, context: ctx || auth_context(user))
  end

  describe "createCollection" do
    let(:mutation) do
      "mutation($title: String!, $visibility: CollectionVisibilityEnum) { createCollection(input: { title: $title, visibility: $visibility }) { collection { id title visibility mode } errors } }"
    end

    it "creates a collection with private/unordered defaults", :aggregate_failures do
      data = gql_data(gql(mutation, { title: "Beginners" }), "createCollection")
      expect(data["errors"]).to be_empty
      expect(data["collection"]).to include("title" => "Beginners", "visibility" => "PRIVATE", "mode" => "UNORDERED")
    end

    it "rejects a stubbed visibility tier", :aggregate_failures do
      data = gql_data(gql(mutation, { title: "X", visibility: "PATRONS_ONLY" }), "createCollection")
      expect(data["collection"]).to be_nil
      expect(data["errors"].first).to include("Unsupported visibility")
    end

    it "requires authentication" do
      expect(gql_errors(gql(mutation, { title: "X" }, {})).first["message"]).to eq("Authentication required")
    end
  end

  describe "updateCollection" do
    let(:mutation) do
      "mutation($id: ID!, $attrs: CollectionAttrsInput!) { updateCollection(input: { id: $id, attrs: $attrs }) { collection { title visibility mode } errors } }"
    end

    it "updates title, visibility, and mode" do
      collection = create(:collection, author: user)
      data = gql_data(gql(mutation, { id: collection.id, attrs: { title: "New", visibility: "PUBLIC", mode: "SEQUENCE" } }), "updateCollection", "collection")
      expect(data).to include("title" => "New", "visibility" => "PUBLIC", "mode" => "SEQUENCE")
    end
  end

  describe "addPuzzleToCollection" do
    let(:mutation) { "mutation($c: ID!, $p: ID!) { addPuzzleToCollection(input: { collectionId: $c, puzzleId: $p }) { collection { id } errors } }" }

    it "appends a puzzle and is idempotent", :aggregate_failures do
      collection = create(:collection, author: user)
      puzzle = create(:puzzle, author: user)
      2.times { gql(mutation, { c: collection.id, p: puzzle.id }) }
      expect(collection.puzzle_entries.count).to eq(1)
    end

    it "does not add another author's puzzle" do
      collection = create(:collection, author: user)
      message = gql_errors(gql(mutation, { c: collection.id, p: create(:puzzle).id })).first["message"]
      expect(message).to eq("Puzzle not found")
    end
  end

  describe "reorder and remove" do
    let(:collection) { create(:collection, author: user) }
    let!(:first_entry) { create(:collection_entry, collection:, puzzle: create(:puzzle, author: user), position: 0) }
    let!(:second_entry) { create(:collection_entry, collection:, puzzle: create(:puzzle, author: user), position: 1) }

    it "reorders entries by the given id list" do
      m = "mutation($c: ID!, $ids: [ID!]!) { reorderCollectionEntries(input: { collectionId: $c, orderedEntryIds: $ids }) { collection { id } errors } }"
      gql(m, { c: collection.id, ids: [ second_entry.id, first_entry.id ] })
      expect(collection.reload.puzzles.pluck(:id)).to eq([ second_entry.entryable_id, first_entry.entryable_id ])
    end

    it "removes a puzzle entry without deleting the puzzle", :aggregate_failures do
      m = "mutation($c: ID!, $e: ID!) { removeCollectionEntry(input: { collectionId: $c, entryId: $e }) { collection { id } errors } }"
      gql(m, { c: collection.id, e: first_entry.id })
      expect(collection.reload.puzzles.pluck(:id)).to eq([ second_entry.entryable_id ])
      expect(Puzzle.exists?(first_entry.entryable_id)).to be(true)
    end
  end

  describe "deleteCollection" do
    it "deletes a collection" do
      collection = create(:collection, author: user)
      m = "mutation($id: ID!) { deleteCollection(input: { id: $id }) { success errors } }"
      expect(gql_data(gql(m, { id: collection.id }), "deleteCollection", "success")).to be(true)
    end
  end
end
