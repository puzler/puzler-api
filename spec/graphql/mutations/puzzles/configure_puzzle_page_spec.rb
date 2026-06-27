require "rails_helper"

RSpec.describe "Mutation: configurePuzzlePage", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzleId: ID!, $override: Boolean) {
        configurePuzzlePage(input: { puzzleId: $puzzleId, commentsRequireSolveOverride: $override }) {
          puzzle { id commentsRequireSolveOverride }
          errors
        }
      }
    GQL
  end
  let(:user) { create(:user) }
  let(:puzzle) { create(:puzzle, :published, author: user) }

  it "stores the comment-gate override" do
    data = gql_data(
      execute_query(mutation, variables: { puzzleId: puzzle.id, override: true }, context: auth_context(user)),
      "configurePuzzlePage", "puzzle"
    )
    expect(data["commentsRequireSolveOverride"]).to be(true)
  end

  it "requires the author" do
    result = execute_query(mutation, variables: { puzzleId: puzzle.id, override: true }, context: auth_context(create(:user)))
    expect(gql_errors(result).first["message"]).to eq("Puzzle not found")
  end
end
