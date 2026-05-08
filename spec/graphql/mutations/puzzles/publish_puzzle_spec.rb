require "rails_helper"

RSpec.describe "Mutation: publishPuzzle", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($id: ID!, $tagSlugs: [String!]) {
        publishPuzzle(input: { id: $id, tagSlugs: $tagSlugs }) {
          puzzle { id status publishedAt }
          errors
        }
      }
    GQL
  end

  let(:user)   { create(:user) }
  let(:puzzle) { create(:puzzle, author: user) }

  context "when the puzzle has a solution" do
    it "publishes the puzzle", :aggregate_failures do
      result = execute_query(mutation, variables: { id: puzzle.id }, context: auth_context(user))
      data = gql_data(result, "publishPuzzle")
      expect(data["errors"]).to be_empty
      expect(data["puzzle"]["status"]).to eq("published")
      expect(data["puzzle"]["publishedAt"]).not_to be_nil
    end

    it "attaches tags when slugs are provided" do
      tag = create(:tag)
      execute_query(mutation, variables: { id: puzzle.id, tagSlugs: [ tag.slug ] }, context: auth_context(user))
      expect(puzzle.reload.tags).to include(tag)
    end
  end

  context "when the puzzle has no solution" do
    let(:puzzle) { create(:puzzle, :without_solution, author: user) }

    it "returns an error" do
      result = execute_query(mutation, variables: { id: puzzle.id }, context: auth_context(user))
      expect(gql_errors(result).first["message"]).to eq("Solution required before publishing")
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { id: puzzle.id })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
