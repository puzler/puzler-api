require "rails_helper"

RSpec.describe "Mutation: updatePuzzlePreferences", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($attrs: PuzzlePreferencesInput!) {
        updatePuzzlePreferences(input: { attrs: $attrs }) {
          user { puzzlePreferences { includeSolutionInSudokupadExport commentsRequireSolveDefault } }
          errors
        }
      }
    GQL
  end
  let(:user) { create(:user) }

  def update(attrs, context: auth_context(user))
    execute_query(mutation, variables: { attrs: attrs }, context: context)
  end

  it "updates only the provided fields", :aggregate_failures do
    prefs = gql_data(update({ includeSolutionInSudokupadExport: false }), "updatePuzzlePreferences", "user", "puzzlePreferences")
    expect(prefs).to eq("includeSolutionInSudokupadExport" => false, "commentsRequireSolveDefault" => false)
    expect(user.reload.include_solution_in_sudokupad_export).to be(false)
  end

  it "requires authentication" do
    result = update({ commentsRequireSolveDefault: true }, context: {})
    expect(gql_errors(result).first["message"]).to eq("Authentication required")
  end
end
