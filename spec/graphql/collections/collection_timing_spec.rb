require "rails_helper"

RSpec.describe "Collection timing", type: :graphql do
  let(:author) { create(:user) }
  let(:collection) { create(:collection, author:, visibility: :public, timed: true) }
  let(:first) { create(:puzzle, :published, author:) }
  let(:second) { create(:puzzle, :published, author:) }

  before do
    create(:collection_entry, collection:, puzzle: first, position: 0)
    create(:collection_entry, collection:, puzzle: second, position: 1)
  end

  def record_mutation
    "mutation($c: ID!, $p: ID!, $s: Int!) { recordCollectionSolveTime(input: { collectionId: $c, puzzleId: $p, seconds: $s }) { recorded errors } }"
  end

  def board_query
    "query($c: ID!) { collectionLeaderboard(collectionId: $c) { rank username displayName totalSeconds } }"
  end

  def rec(user, puzzle, secs)
    execute_query(record_mutation, variables: { c: collection.id, p: puzzle.id, s: secs }, context: auth_context(user))
  end

  describe "recordCollectionSolveTime" do
    it "keeps the best (lowest) time", :aggregate_failures do
      solver = create(:user)
      rec(solver, first, 30)
      rec(solver, first, 50)
      expect(CollectionSolveTime.find_by(collection:, puzzle: first, user: solver).seconds).to eq(30)
    end

    it "requires authentication" do
      result = execute_query(record_mutation, variables: { c: collection.id, p: first.id, s: 10 })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end

  describe "collectionLeaderboard" do
    let(:speedy) { create(:user, username: "speedy", display_name: "Speedy Gonzales") }

    before do
      create(:collection_solve_time, collection:, puzzle: first, user: speedy, seconds: 30)
      create(:collection_solve_time, collection:, puzzle: second, user: speedy, seconds: 45)
      create(:collection_solve_time, collection:, puzzle: first, user: create(:user), seconds: 5)
    end

    it "ranks only solvers who completed every puzzle, by total time" do
      data = gql_data(execute_query(board_query, variables: { c: collection.id }), "collectionLeaderboard")
      expect(data).to eq([ { "rank" => 1, "username" => "speedy", "displayName" => "Speedy Gonzales", "totalSeconds" => 75 } ])
    end
  end
end
