require "rails_helper"

RSpec.describe "Mutation: deleteConstraint", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($id: ID!) {
        deleteConstraint(input: { id: $id }) {
          success
        }
      }
    GQL
  end

  let(:user)        { create(:user) }
  let(:puzzle)      { create(:puzzle, author: user) }
  let!(:constraint) { create(:constraint, puzzle: puzzle) }

  context "when authenticated as the puzzle author" do
    it "deletes the constraint and returns success", :aggregate_failures do
      result = execute_query(mutation, variables: { id: constraint.id }, context: auth_context(user))
      expect(gql_data(result, "deleteConstraint", "success")).to be true
      expect(Constraint.find_by(id: constraint.id)).to be_nil
    end
  end

  context "when authenticated as a different user" do
    it "returns a constraint not found error" do
      other = create(:user)
      result = execute_query(mutation, variables: { id: constraint.id }, context: auth_context(other))
      expect(gql_errors(result).first["message"]).to eq("Constraint not found")
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { id: constraint.id })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
