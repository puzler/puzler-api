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

  describe "puzzles" do
    let(:query) do
      <<~GQL
        query { puzzles { id title } }
      GQL
    end

    it "returns only published public puzzles", :aggregate_failures do
      published = create(:puzzle, :published)
      hidden = [ create(:puzzle), create(:puzzle, :unlisted), create(:puzzle, :access_private) ]
      ids = gql_data(execute_query(query), "puzzles").map { |p| p["id"] }
      expect(ids).to include(published.id.to_s)
      expect(ids).not_to include(*hidden.map { |p| p.id.to_s })
    end

    it "filters by constraint type", :aggregate_failures do
      thermo = create(:puzzle, :published, constraint_types: [ "thermometer" ])
      create(:puzzle, :published, constraint_types: [ "killer_cage" ])
      result = execute_query('query { puzzles(constraintTypes: ["thermometer"]) { id } }')
      expect(gql_data(result, "puzzles").map { |p| p["id"] }).to eq([ thermo.id.to_s ])
    end
  end

  describe "myPuzzles" do
    let(:query) do
      <<~GQL
        query { myPuzzles { id title status } }
      GQL
    end

    context "when authenticated" do
      let(:user)    { create(:user) }
      let!(:mine)   { create(:puzzle, author: user) }
      let!(:others) { create(:puzzle, :published) }

      it "returns only the current user's puzzles", :aggregate_failures do
        ids = gql_data(execute_query(query, context: auth_context(user)), "myPuzzles").map { |p| p["id"] }
        expect(ids).to include(mine.id.to_s)
        expect(ids).not_to include(others.id.to_s)
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
