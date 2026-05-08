require "rails_helper"

RSpec.describe "Mutation: upsertCosmetic", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzleId: ID!, $id: ID, $cosmeticType: String!, $position: JSON!, $style: JSON!) {
        upsertCosmetic(input: {
          puzzleId: $puzzleId, id: $id,
          attrs: { cosmeticType: $cosmeticType, position: $position, style: $style }
        }) {
          cosmetic { id cosmeticType }
          errors
        }
      }
    GQL
  end

  let(:user)     { create(:user) }
  let(:puzzle)   { create(:puzzle, author: user) }
  let(:position) { { "type" => "cell", "cells" => [ "r0c0" ] } }

  context "when creating a new cosmetic" do
    it "creates and returns the cosmetic", :aggregate_failures do
      result = execute_query(mutation,
        variables: { puzzleId: puzzle.id, cosmeticType: "cell_color", position: position, style: { "color" => "#ff0000" } },
        context: auth_context(user))
      expect(gql_data(result, "upsertCosmetic", "errors")).to be_empty
      expect(gql_data(result, "upsertCosmetic", "cosmetic", "cosmeticType")).to eq("cell_color")
    end
  end

  context "when updating an existing cosmetic" do
    let!(:cosmetic) { create(:cosmetic, puzzle: puzzle) }

    it "updates the cosmetic" do
      execute_query(mutation,
        variables: { puzzleId: puzzle.id, id: cosmetic.id,
                     cosmeticType: "cell_color", position: position, style: { "color" => "#00ff00" } },
        context: auth_context(user))
      expect(cosmetic.reload.style["color"]).to eq("#00ff00")
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation,
        variables: { puzzleId: puzzle.id, cosmeticType: "cell_color", position: position, style: { "color" => "#ff0000" } })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
