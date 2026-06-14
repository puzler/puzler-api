require "rails_helper"

RSpec.describe "Collection queries", type: :graphql do
  let(:user) { create(:user) }

  describe "myCollections" do
    it "returns only the current user's collections", :aggregate_failures do
      mine = create(:collection, author: user)
      create(:collection)
      result = execute_query("query { myCollections { id } }", context: auth_context(user))
      expect(gql_data(result, "myCollections").map { |c| c["id"] }).to eq([ mine.id.to_s ])
    end
  end

  describe "collection(id)" do
    let(:query) { "query($id: ID!) { collection(id: $id) { id } }" }

    it "hides a private collection from other users" do
      collection = create(:collection, visibility: :private)
      expect(gql_data(execute_query(query, variables: { id: collection.id }), "collection")).to be_nil
    end

    it "shows a public collection to anyone" do
      collection = create(:collection, visibility: :public)
      expect(gql_data(execute_query(query, variables: { id: collection.id }), "collection", "id")).to eq(collection.id.to_s)
    end
  end

  describe "collectionByToken" do
    it "resolves an unlisted collection by its share token" do
      collection = create(:collection, visibility: :unlisted)
      query = "query($t: String!) { collectionByToken(token: $t) { id } }"
      expect(gql_data(execute_query(query, variables: { t: collection.share_token }), "collectionByToken", "id")).to eq(collection.id.to_s)
    end
  end

  describe "container-only puzzles inside a viewable collection" do
    let(:query) { "query($id: ID!) { collection(id: $id) { puzzles { id shareToken } } }" }
    let(:collection) { create(:collection, author: user, visibility: :public) }
    let(:public_puzzle) { create(:puzzle, :published, author: user) }
    let(:container_puzzle) { create(:puzzle, :containers_only, author: user) }

    before do
      hidden = create(:puzzle, :unlisted, author: user)
      [ public_puzzle, container_puzzle, hidden ].each_with_index do |p, i|
        create(:collection_puzzle, collection:, puzzle: p, position: i)
      end
    end

    def rows
      gql_data(execute_query(query, variables: { id: collection.id }), "collection", "puzzles").index_by { |p| p["id"] }
    end

    it "lists public and container-only puzzles, hiding unlisted/private ones" do
      expect(rows.keys).to contain_exactly(public_puzzle.id.to_s, container_puzzle.id.to_s)
    end

    it "exposes the container-only token but keeps the public puzzle's author-only", :aggregate_failures do
      expect(rows[container_puzzle.id.to_s]["shareToken"]).to eq(container_puzzle.share_token)
      expect(rows[public_puzzle.id.to_s]["shareToken"]).to be_nil
    end
  end
end
