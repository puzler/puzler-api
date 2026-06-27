require "rails_helper"

# The public profile surface on the User type. The throughline is owner-controlled
# privacy: the owner always sees everything; everyone else (logged in or not) sees
# a section only if the owner's preference permits it.
RSpec.describe "Queries: profile", type: :graphql do
  let(:owner) { create(:user) }
  let(:other) { create(:user) }

  # Run `query` for `owner` viewed by `viewer` (nil = anonymous) and dig to the
  # user node.
  def profile(query, viewer: nil)
    ctx = viewer ? auth_context(viewer) : {}
    result = execute_query(query, variables: { username: owner.username }, context: ctx)
    gql_data(result, "user")
  end

  describe "profileStats" do
    let(:query) do
      <<~GQL
        query($username: String!) {
          user(username: $username) {
            profileStats {
              collectionCount seriesCount totalSolvesReceived
              totalFavoritesReceived avgRatingReceived reviewsReceivedCount
            }
          }
        }
      GQL
    end

    before do
      puzzle = create(:puzzle, :published, author: owner, solve_count: 10, favorite_count: 3, avg_rating: 4.0)
      create(:collection, author: owner, visibility: :public)
      create(:series, author: owner, visibility: :public)
      create(:comment, puzzle: puzzle, user: other) # a review received
    end

    context "when show_stats is on" do
      before { owner.update!(show_stats: true) }

      it "exposes aggregate stats to any viewer" do
        expect(profile(query, viewer: other)["profileStats"]).to include(
          "collectionCount" => 1, "seriesCount" => 1, "totalSolvesReceived" => 10,
          "totalFavoritesReceived" => 3, "avgRatingReceived" => 4.0, "reviewsReceivedCount" => 1
        )
      end
    end

    context "when show_stats is off" do
      before { owner.update!(show_stats: false) }

      it "hides stats from other viewers and anonymous", :aggregate_failures do
        expect(profile(query, viewer: other)["profileStats"]).to be_nil
        expect(profile(query)["profileStats"]).to be_nil
      end

      it "still shows stats to the owner" do
        expect(profile(query, viewer: owner)["profileStats"]).not_to be_nil
      end
    end
  end

  # Drive the content-driven profile tabs: these counts must be public even when
  # the owner has hidden their aggregate stats panel.
  describe "public content counts (always public)" do
    let(:query) do
      <<~GQL
        query($username: String!) {
          user(username: $username) { puzzleCount publicCollectionCount publicSeriesCount }
        }
      GQL
    end

    before do
      create(:puzzle, :published, author: owner)
      create(:collection, author: owner, visibility: :public)
      create(:collection, author: owner, visibility: :private)
      create(:series, author: owner, visibility: :public)
      owner.update!(show_stats: false)
    end

    it "exposes public puzzle, collection, and series counts to anyone, ignoring show_stats", :aggregate_failures do
      data = profile(query, viewer: other)
      expect(data["puzzleCount"]).to eq(1)
      expect(data["publicCollectionCount"]).to eq(1)
      expect(data["publicSeriesCount"]).to eq(1)
    end
  end

  describe "solvedPuzzles (four-level gate)" do
    let(:query) do
      <<~GQL
        query($username: String!) {
          user(username: $username) {
            solvedPuzzles {
              nodes { puzzle { id } ownerRating { stars } ownerReview { body } }
              pageInfo { totalCount }
            }
          }
        }
      GQL
    end

    let!(:solved) { create(:puzzle, :published) }

    before do
      create(:puzzle_play, :with_user, :solved, user: owner, puzzle: solved)
      create(:rating, user: owner, puzzle: solved, stars: 5, difficulty_vote: 4)
      create(:comment, user: owner, puzzle: solved, body: "loved it")
    end

    it "shows nothing to others at the hidden level" do
      owner.update!(solve_history_visibility: :hidden)
      expect(profile(query, viewer: other)["solvedPuzzles"]["nodes"]).to be_empty
    end

    it "shows nothing to others at the count level (count lives on solveCount)" do
      owner.update!(solve_history_visibility: :count)
      expect(profile(query, viewer: other)["solvedPuzzles"]["nodes"]).to be_empty
    end

    it "lists puzzles but no rating/review at the puzzles level", :aggregate_failures do
      owner.update!(solve_history_visibility: :puzzles)
      node = profile(query, viewer: other)["solvedPuzzles"]["nodes"].first
      expect(node["puzzle"]["id"]).to eq(solved.id.to_s)
      expect(node["ownerRating"]).to be_nil
      expect(node["ownerReview"]).to be_nil
    end

    it "includes the owner's rating and review at the detailed level", :aggregate_failures do
      owner.update!(solve_history_visibility: :detailed)
      node = profile(query, viewer: other)["solvedPuzzles"]["nodes"].first
      expect(node["ownerRating"]["stars"]).to eq(5)
      expect(node["ownerReview"]["body"]).to eq("loved it")
    end

    it "shows the owner the full detail even when hidden from others", :aggregate_failures do
      owner.update!(solve_history_visibility: :hidden)
      node = profile(query, viewer: owner)["solvedPuzzles"]["nodes"].first
      expect(node["puzzle"]["id"]).to eq(solved.id.to_s)
      expect(node["ownerRating"]["stars"]).to eq(5)
      expect(node["ownerReview"]["body"]).to eq("loved it")
    end

    it "omits puzzles that are no longer publicly visible" do
      owner.update!(solve_history_visibility: :detailed)
      private_puzzle = create(:puzzle, :access_private)
      create(:puzzle_play, :with_user, :solved, user: owner, puzzle: private_puzzle)
      ids = profile(query, viewer: other)["solvedPuzzles"]["nodes"].map { |n| n["puzzle"]["id"] }
      expect(ids).to contain_exactly(solved.id.to_s)
    end
  end

  describe "reviewsReceived (always public)" do
    let(:query) do
      <<~GQL
        query($username: String!) {
          user(username: $username) {
            reviewsReceived { nodes { body user { username } puzzle { id } } pageInfo { totalCount } }
          }
        }
      GQL
    end

    let!(:puzzle) { create(:puzzle, :published, author: owner) }

    before do
      create(:comment, puzzle: puzzle, user: other, body: "nice")
      create(:comment, :reply, puzzle: puzzle, user: other) # reply, should be excluded
      create(:comment, puzzle: create(:puzzle, :published, author: other), user: owner) # on someone else's puzzle
    end

    it "returns only top-level reviews on the owner's public puzzles", :aggregate_failures do
      nodes = profile(query)["reviewsReceived"]["nodes"]
      expect(nodes.size).to eq(1)
      expect(nodes.first["body"]).to eq("nice")
      expect(nodes.first["puzzle"]["id"]).to eq(puzzle.id.to_s)
    end
  end

  describe "favoritedPuzzles (toggle)" do
    let(:query) do
      <<~GQL
        query($username: String!) {
          user(username: $username) { favoritedPuzzles { nodes { id } } }
        }
      GQL
    end

    let!(:fav) { create(:puzzle, :published) }

    before { create(:favorite, user: owner, puzzle: fav) }

    it "is hidden from others when show_favorites is off" do
      owner.update!(show_favorites: false)
      expect(profile(query, viewer: other)["favoritedPuzzles"]["nodes"]).to be_empty
    end

    it "is visible to others when show_favorites is on" do
      owner.update!(show_favorites: true)
      ids = profile(query, viewer: other)["favoritedPuzzles"]["nodes"].map { |n| n["id"] }
      expect(ids).to contain_exactly(fav.id.to_s)
    end

    it "is visible to the owner even when off" do
      owner.update!(show_favorites: false)
      expect(profile(query, viewer: owner)["favoritedPuzzles"]["nodes"]).not_to be_empty
    end
  end

  describe "subscribedSeries (toggle)" do
    let(:query) do
      <<~GQL
        query($username: String!) {
          user(username: $username) { subscribedSeries { nodes { id } } }
        }
      GQL
    end

    let!(:series) { create(:series, visibility: :public) }

    before { create(:series_subscription, user: owner, series: series) }

    it "is hidden from others when show_subscriptions is off" do
      owner.update!(show_subscriptions: false)
      expect(profile(query, viewer: other)["subscribedSeries"]["nodes"]).to be_empty
    end

    it "is visible to others when show_subscriptions is on" do
      owner.update!(show_subscriptions: true)
      ids = profile(query, viewer: other)["subscribedSeries"]["nodes"].map { |n| n["id"] }
      expect(ids).to contain_exactly(series.id.to_s)
    end
  end

  describe "activity (toggle + solve gate)" do
    let(:query) do
      <<~GQL
        query($username: String!) {
          user(username: $username) { activity { kind } }
        }
      GQL
    end

    before do
      create(:puzzle, :published, author: owner) # PUBLISHED_PUZZLE
      create(:comment, user: owner, puzzle: create(:puzzle, :published), body: "good") # REVIEW_WRITTEN
      create(:puzzle_play, :with_user, :solved, user: owner, puzzle: create(:puzzle, :published)) # SOLVE
    end

    it "is empty for others when show_activity is off" do
      owner.update!(show_activity: false)
      expect(profile(query, viewer: other)["activity"]).to be_empty
    end

    it "includes solves when the solve-history level permits" do
      owner.update!(show_activity: true, solve_history_visibility: :puzzles)
      kinds = profile(query, viewer: other)["activity"].map { |a| a["kind"] }
      expect(kinds).to include("PUBLISHED_PUZZLE", "REVIEW_WRITTEN", "SOLVE")
    end

    it "suppresses solves when the solve-history level is below puzzles", :aggregate_failures do
      owner.update!(show_activity: true, solve_history_visibility: :count)
      kinds = profile(query, viewer: other)["activity"].map { |a| a["kind"] }
      expect(kinds).to include("PUBLISHED_PUZZLE", "REVIEW_WRITTEN")
      expect(kinds).not_to include("SOLVE")
    end
  end

  describe "visibility preference fields" do
    let(:query) do
      <<~GQL
        query($username: String!) {
          user(username: $username) {
            profileVisibility { solveHistory stats favorites subscriptions activity }
          }
        }
      GQL
    end

    it "exposes the prefs publicly so the client knows which tabs to render", :aggregate_failures do
      owner.update!(solve_history_visibility: :detailed, show_favorites: true)
      vis = profile(query)["profileVisibility"]
      expect(vis["solveHistory"]).to eq("DETAILED")
      expect(vis["favorites"]).to be(true)
    end
  end
end
