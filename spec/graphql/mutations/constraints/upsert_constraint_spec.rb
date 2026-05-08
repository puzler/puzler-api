require "rails_helper"

RSpec.describe "Mutation: upsertConstraint", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzleId: ID!, $id: ID, $constraintType: String!, $data: JSON!) {
        upsertConstraint(input: {
          puzzleId: $puzzleId, id: $id,
          attrs: { constraintType: $constraintType, data: $data }
        }) {
          constraint { id constraintType data }
          errors
        }
      }
    GQL
  end

  let(:user)   { create(:user) }
  let(:puzzle) { create(:puzzle, author: user) }
  let(:data)   { { "cells" => [ "r0c0", "r0c1" ], "sum" => 12 } }

  context "when creating a new constraint" do
    it "creates and returns the constraint", :aggregate_failures do
      result = execute_query(mutation, variables: { puzzleId: puzzle.id, constraintType: "killer_cage", data: data }, context: auth_context(user))
      record = gql_data(result, "upsertConstraint", "constraint")
      expect(record["constraintType"]).to eq("killer_cage")
      expect(gql_data(result, "upsertConstraint", "errors")).to be_empty
    end
  end

  context "when updating an existing constraint" do
    let!(:constraint) { create(:constraint, puzzle: puzzle) }

    it "updates the constraint", :aggregate_failures do
      vars = { puzzleId: puzzle.id, id: constraint.id, constraintType: "killer_cage", data: { "cells" => [ "r1c1" ], "sum" => 5 } }
      result = execute_query(mutation, variables: vars, context: auth_context(user))
      expect(gql_data(result, "upsertConstraint", "errors")).to be_empty
      expect(constraint.reload.data["sum"]).to eq(5)
    end
  end

  context "when authenticated as a different user" do
    it "returns a puzzle not found error" do
      other = create(:user)
      result = execute_query(mutation,
        variables: { puzzleId: puzzle.id, constraintType: "killer_cage", data: data },
        context: auth_context(other))
      expect(gql_errors(result).first["message"]).to eq("Puzzle not found")
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation,
        variables: { puzzleId: puzzle.id, constraintType: "killer_cage", data: data })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
