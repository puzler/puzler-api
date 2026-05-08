require "rails_helper"

RSpec.describe "Mutation: deleteCosmetic", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($id: ID!) {
        deleteCosmetic(input: { id: $id }) {
          success
        }
      }
    GQL
  end

  let(:user)      { create(:user) }
  let(:puzzle)    { create(:puzzle, author: user) }
  let!(:cosmetic) { create(:cosmetic, puzzle: puzzle) }

  context "when authenticated as the puzzle author" do
    it "deletes the cosmetic and returns success", :aggregate_failures do
      result = execute_query(mutation, variables: { id: cosmetic.id }, context: auth_context(user))
      expect(gql_data(result, "deleteCosmetic", "success")).to be true
      expect(Cosmetic.find_by(id: cosmetic.id)).to be_nil
    end
  end

  context "when authenticated as a different user" do
    it "returns a cosmetic not found error" do
      other = create(:user)
      result = execute_query(mutation, variables: { id: cosmetic.id }, context: auth_context(other))
      expect(gql_errors(result).first["message"]).to eq("Cosmetic not found")
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { id: cosmetic.id })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
