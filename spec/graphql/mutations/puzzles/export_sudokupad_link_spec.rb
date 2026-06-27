require "rails_helper"

RSpec.describe "Mutation: exportSudokupadLink", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($definition: JSON!, $solution: JSON, $includeSolution: Boolean) {
        exportSudokupadLink(input: { definition: $definition, solution: $solution, includeSolution: $includeSolution }) {
          url
          warnings
          errors
        }
      }
    GQL
  end
  let(:user) { create(:user) }
  let(:definition) { { "grid" => { "rows" => 9, "cols" => 9 }, "meta" => { "name" => "X" }, "givenDigits" => { "r0c0" => 1 } } }
  let(:endpoint) { "https://sudokupad.app/admin/createlink" }

  def run(vars, context: auth_context(user))
    gql_data(execute_query(mutation, variables: vars, context: context), "exportSudokupadLink")
  end

  it "builds a short link from the definition", :aggregate_failures do
    stub_request(:post, endpoint).to_return(status: 200, body: { result: "success", shortid: "ex1" }.to_json)
    data = run({ definition: definition, includeSolution: false })
    expect(data["url"]).to eq("https://sudokupad.app/ex1")
    expect(data["errors"]).to be_empty
  end

  it "falls back to the long URL when createlink fails" do
    stub_request(:post, endpoint).to_return(status: 500)
    expect(run({ definition: definition })["url"]).to start_with("https://sudokupad.app/?puzzleid=")
  end

  it "errors on a non-square grid (no network call)", :aggregate_failures do
    data = run({ definition: { "grid" => { "rows" => 9, "cols" => 6 } } })
    expect(data["url"]).to be_nil
    expect(data["errors"].first).to include("square grid")
    expect(a_request(:post, endpoint)).not_to have_been_made
  end

  it "requires authentication" do
    result = execute_query(mutation, variables: { definition: definition }, context: {})
    expect(gql_errors(result).first["message"]).to eq("Authentication required")
  end
end
