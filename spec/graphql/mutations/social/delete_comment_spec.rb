require "rails_helper"

RSpec.describe "Mutation: deleteComment", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($id: ID!) {
        deleteComment(input: { id: $id }) {
          success
        }
      }
    GQL
  end

  let(:user)     { create(:user) }
  let!(:comment) { create(:comment, user: user) }

  context "when authenticated as the comment author" do
    it "deletes the comment and returns success", :aggregate_failures do
      result = execute_query(mutation, variables: { id: comment.id }, context: auth_context(user))
      expect(gql_data(result, "deleteComment", "success")).to be true
      expect(Comment.find_by(id: comment.id)).to be_nil
    end
  end

  context "when authenticated as a different user" do
    it "returns a comment not found error" do
      other = create(:user)
      result = execute_query(mutation, variables: { id: comment.id }, context: auth_context(other))
      expect(gql_errors(result).first["message"]).to eq("Comment not found")
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { id: comment.id })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
