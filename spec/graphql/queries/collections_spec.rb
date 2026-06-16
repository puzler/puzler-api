require "rails_helper"

RSpec.describe "Collection queries", type: :graphql do
  let(:user) { create(:user) }

  describe "myCollections" do
    let(:query) do
      "query($f: ListingFilterInput) { myCollections(filter: $f) { nodes { id title avgRating solveCount } pageInfo { totalCount } } }"
    end

    def node_ids(result)
      gql_data(result, "myCollections", "nodes").map { |c| c["id"] }
    end

    it "returns only the current user's collections", :aggregate_failures do
      mine = create(:collection, author: user)
      create(:collection)
      expect(node_ids(execute_query(query, context: auth_context(user)))).to eq([ mine.id.to_s ])
    end

    it "searches by title" do
      match = create(:collection, author: user, title: "Killer Weekly")
      create(:collection, author: user, title: "Thermo Monthly")
      result = execute_query(query, variables: { f: { search: "killer" } }, context: auth_context(user))
      expect(node_ids(result)).to contain_exactly(match.id.to_s)
    end

    it "sorts by member-derived rating", :aggregate_failures do
      high = create(:collection, author: user, avg_rating: 4.8)
      low = create(:collection, author: user, avg_rating: 1.2)
      result = execute_query(query, variables: { f: { sort: "RATING" } }, context: auth_context(user))
      expect(node_ids(result)).to eq([ high.id.to_s, low.id.to_s ])
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
