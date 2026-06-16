require "rails_helper"

RSpec.describe "Queries: puzzles", type: :graphql do
  describe "puzzle(id:)" do
    let(:query) do
      <<~GQL
        query($id: ID!) {
          puzzle(id: $id) { id title status }
        }
      GQL
    end

    context "when the puzzle is published" do
      let(:puzzle) { create(:puzzle, :published) }

      it "returns the puzzle" do
        result = execute_query(query, variables: { id: puzzle.id })
        expect(gql_data(result, "puzzle", "id")).to eq(puzzle.id.to_s)
      end
    end

    context "when the puzzle is a draft" do
      let(:puzzle) { create(:puzzle) }

      it "returns nil for other users" do
        result = execute_query(query, variables: { id: puzzle.id })
        expect(gql_data(result, "puzzle")).to be_nil
      end

      it "returns the puzzle for the author" do
        result = execute_query(query, variables: { id: puzzle.id }, context: auth_context(puzzle.author))
        expect(gql_data(result, "puzzle", "id")).to eq(puzzle.id.to_s)
      end
    end

    it "returns nil for a non-existent puzzle" do
      result = execute_query(query, variables: { id: 0 })
      expect(gql_data(result, "puzzle")).to be_nil
    end
  end

  describe "authorName" do
    let(:query) { "query($id: ID!) { puzzle(id: $id) { authorName } }" }

    def published_with_author(author_meta)
      puzzle = create(:puzzle, :published)
      version = create(:puzzle_version, puzzle:, definition: { "meta" => { "author" => author_meta } })
      puzzle.update!(published_version: version)
      puzzle
    end

    it "returns the free-text author from the published version's metadata" do
      puzzle = published_with_author("Anonymous Setter")
      expect(gql_data(execute_query(query, variables: { id: puzzle.id }), "puzzle", "authorName")).to eq("Anonymous Setter")
    end

    it "is null when the author left it blank (UI falls back to the display name)" do
      puzzle = published_with_author("   ")
      expect(gql_data(execute_query(query, variables: { id: puzzle.id }), "puzzle", "authorName")).to be_nil
    end
  end

  describe "puzzles (archive connection)" do
    let(:query) do
      "query($filter: ListingFilterInput) { puzzles(filter: $filter) { nodes { id } pageInfo { totalCount } } }"
    end

    def archive_ids(context: {}, **filter)
      result = execute_query("query($filter: ListingFilterInput) { puzzles(filter: $filter) { nodes { id } } }",
        variables: { filter: }, context:)
      gql_data(result, "puzzles", "nodes").map { |p| p["id"] }
    end

    it "returns only published public puzzles" do
      published = create(:puzzle, :published)
      create(:puzzle); create(:puzzle, :unlisted); create(:puzzle, :access_private)
      expect(archive_ids).to eq([ published.id.to_s ])
    end

    it "filters by constraint type" do
      thermo = create(:puzzle, :published, constraint_types: [ "thermometer" ])
      create(:puzzle, :published, constraint_types: [ "killer_cage" ])
      expect(archive_ids(constraintTypes: [ "thermometer" ])).to eq([ thermo.id.to_s ])
    end

    it "searches by setter username and display name", :aggregate_failures do
      setter = create(:user, username: "zelda_sets", display_name: "Zelda")
      mine = create(:puzzle, :published, author: setter)
      create(:puzzle, :published)
      expect(archive_ids(search: "zelda_sets")).to eq([ mine.id.to_s ])
      expect(archive_ids(search: "Zelda")).to eq([ mine.id.to_s ])
    end

    it "filters by difficulty level via effective difficulty", :aggregate_failures do
      easy = create(:puzzle, :published, author_difficulty: 1, effective_difficulty: 1.0)
      hard = create(:puzzle, :published, author_difficulty: 5, effective_difficulty: 4.8)
      create(:puzzle, :published, effective_difficulty: nil)
      expect(archive_ids(difficulties: [ 1 ])).to eq([ easy.id.to_s ])
      expect(archive_ids(difficulties: [ 5 ])).to eq([ hard.id.to_s ])
    end

    it "filters by minimum rating, featured, and grid size", :aggregate_failures do
      top = create(:puzzle, :published, :featured, avg_rating: 4.6, grid_rows: 9, grid_cols: 9)
      create(:puzzle, :published, avg_rating: 2.0, grid_rows: 6, grid_cols: 6)
      expect(archive_ids(minRating: 4.0)).to eq([ top.id.to_s ])
      expect(archive_ids(featured: true)).to eq([ top.id.to_s ])
      expect(archive_ids(gridSizes: [ "9x9" ])).to eq([ top.id.to_s ])
    end

    it "filters by setter tier and time range", :aggregate_failures do
      pro = create(:user, setter_tier: :experienced)
      pro_puzzle = create(:puzzle, :published, author: pro)
      create(:puzzle, :published, published_at: 2.years.ago)
      expect(archive_ids(setterTier: "EXPERIENCED")).to eq([ pro_puzzle.id.to_s ])
      expect(archive_ids(timeRange: "THIS_MONTH")).to eq([ pro_puzzle.id.to_s ])
    end

    context "when filtering by my status" do
      let(:viewer) { create(:user) }
      let!(:solved) { create(:puzzle, :published) }
      let!(:fav) { create(:puzzle, :published) }

      before do
        create(:puzzle_play, puzzle: solved, user: viewer, is_solved: true)
        create(:favorite, puzzle: fav, user: viewer)
      end

      it "matches the viewer's solved/favorited, and no-ops when anonymous", :aggregate_failures do
        expect(archive_ids(context: auth_context(viewer), myStatus: "SOLVED")).to eq([ solved.id.to_s ])
        expect(archive_ids(context: auth_context(viewer), myStatus: "FAVORITED")).to eq([ fav.id.to_s ])
        expect(archive_ids(myStatus: "SOLVED").size).to eq(2) # anonymous: unfiltered
      end
    end

    it "paginates with totalCount", :aggregate_failures do
      create_list(:puzzle, 3, :published)
      result = execute_query(query, variables: { filter: { perPage: 2 } })
      expect(gql_data(result, "puzzles", "nodes").size).to eq(2)
      expect(gql_data(result, "puzzles", "pageInfo", "totalCount")).to eq(3)
    end
  end

  describe "myPuzzles" do
    let(:query) do
      <<~GQL
        query($filter: ListingFilterInput) {
          myPuzzles(filter: $filter) {
            nodes { id title status }
            pageInfo { page perPage totalCount totalPages hasNextPage hasPreviousPage }
          }
        }
      GQL
    end

    def node_ids(result)
      gql_data(result, "myPuzzles", "nodes").map { |p| p["id"] }
    end

    context "when authenticated" do
      let(:user)    { create(:user) }
      let!(:mine)   { create(:puzzle, author: user) }
      let!(:others) { create(:puzzle, :published) }

      # Run the listing for `user` with the given filter and return node IDs.
      def filtered(filter = {})
        node_ids(execute_query(query, variables: { filter: }, context: auth_context(user)))
      end

      # Create three of the user's puzzles whose alphabetical order matches their
      # ascending rating/solve order, and return the expected alphabetical IDs.
      def sortable_setup
        a = create(:puzzle, author: user, title: "Aardvark", avg_rating: 1.0, solve_count: 5)
        z = create(:puzzle, author: user, title: "Zebra", avg_rating: 5.0, solve_count: 50)
        mine.update!(title: "Middle", avg_rating: 3.0, solve_count: 25)
        others.destroy
        [ a.id.to_s, mine.id.to_s, z.id.to_s ]
      end

      it "returns only the current user's puzzles", :aggregate_failures do
        expect(filtered).to include(mine.id.to_s)
        expect(filtered).not_to include(others.id.to_s)
      end

      it "searches across title, description, and author" do
        match = create(:puzzle, author: user, title: "Whispers of Spring")
        create(:puzzle, author: user, title: "Unrelated", description: "nothing here")
        expect(filtered(search: "whispers")).to contain_exactly(match.id.to_s)
      end

      it "filters constraints with ANY (overlap) vs ALL (contains)", :aggregate_failures do
        both = create(:puzzle, author: user, constraint_types: %w[thermometer arrow])
        thermo = create(:puzzle, author: user, constraint_types: %w[thermometer])
        expect(filtered(constraintTypes: %w[thermometer arrow], matchMode: "ANY")).to contain_exactly(both.id.to_s, thermo.id.to_s)
        expect(filtered(constraintTypes: %w[thermometer arrow], matchMode: "ALL")).to contain_exactly(both.id.to_s)
      end

      it "filters to any of several visibilities" do
        unlisted = create(:puzzle, :unlisted, author: user)
        published = create(:puzzle, :published, author: user)
        expect(filtered(visibilities: %w[UNLISTED PUBLIC])).to contain_exactly(unlisted.id.to_s, published.id.to_s)
      end

      it "treats DRAFT as a status bucket separate from visibility", :aggregate_failures do
        draft = mine # the unpublished fixture puzzle
        published = create(:puzzle, :published, author: user)
        expect(filtered(visibilities: %w[DRAFT])).to contain_exactly(draft.id.to_s)
        expect(filtered(visibilities: %w[PUBLIC])).to contain_exactly(published.id.to_s)
      end

      it "filters by folder, including unfiled", :aggregate_failures do
        folder = create(:folder, author: user)
        filed = create(:puzzle, author: user, folder:)
        expect(filtered(folderId: folder.id.to_s)).to contain_exactly(filed.id.to_s)
        expect(filtered(folderId: "unfiled")).to include(mine.id.to_s)
        expect(filtered(folderId: "unfiled")).not_to include(filed.id.to_s)
      end

      it "sorts by title, rating, and solves", :aggregate_failures do
        alphabetical = sortable_setup
        expect(filtered(sort: "ALPHABETICAL")).to eq(alphabetical)
        expect(filtered(sort: "RATING")).to eq(alphabetical.reverse)
        expect(filtered(sort: "SOLVES")).to eq(alphabetical.reverse)
      end

      it "paginates and reports page metadata", :aggregate_failures do
        create_list(:puzzle, 4, author: user)
        result = execute_query(query, variables: { filter: { perPage: 2 } }, context: auth_context(user))
        expect(gql_data(result, "myPuzzles", "nodes").size).to eq(2)
        expect(gql_data(result, "myPuzzles", "pageInfo")).to include("totalCount" => 5, "totalPages" => 3, "hasNextPage" => true)
      end
    end

    context "when unauthenticated" do
      it "returns an authentication error" do
        result = execute_query(query)
        expect(gql_errors(result).first["message"]).to eq("Authentication required")
      end
    end
  end
end
