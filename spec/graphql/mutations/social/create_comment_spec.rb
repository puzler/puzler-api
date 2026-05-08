require "rails_helper"

RSpec.describe "Mutation: createComment", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzleId: ID!, $body: String!, $parentId: ID) {
        createComment(input: { puzzleId: $puzzleId, body: $body, parentId: $parentId }) {
          comment { id body }
          errors
        }
      }
    GQL
  end

  let(:user)   { create(:user) }
  let(:puzzle) { create(:puzzle, :published) }

  context "when authenticated" do
    it "creates a top-level comment", :aggregate_failures do
      result = execute_query(mutation, variables: { puzzleId: puzzle.id, body: "Great puzzle!" }, context: auth_context(user))
      data = gql_data(result, "createComment")
      expect(data["errors"]).to be_empty
      expect(data["comment"]["body"]).to eq("Great puzzle!")
    end

    it "creates a reply when parentId is provided", :aggregate_failures do
      parent = create(:comment, puzzle: puzzle)
      result = execute_query(mutation, variables: { puzzleId: puzzle.id, body: "I agree!", parentId: parent.id }, context: auth_context(user))
      expect(gql_data(result, "createComment", "errors")).to be_empty
      expect(Comment.last.parent_id).to eq(parent.id)
    end

    it "returns an error for a non-existent puzzle" do
      result = execute_query(mutation, variables: { puzzleId: 0, body: "Hello" }, context: auth_context(user))
      expect(gql_errors(result).first["message"]).to eq("Puzzle not found")
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { puzzleId: puzzle.id, body: "Hi" })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
