require "rails_helper"

RSpec.describe "Mutation: updatePageDescription", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzleId: ID!, $html: String!) {
        updatePageDescription(input: { puzzleId: $puzzleId, html: $html }) {
          puzzle { id pageDescriptionHtml }
          errors
        }
      }
    GQL
  end
  let(:user) { create(:user) }
  let(:puzzle) { create(:puzzle, author: user) }

  def run(html, context: auth_context(user), id: puzzle.id)
    execute_query(mutation, variables: { puzzleId: id, html: html }, context: context)
  end

  it "stores sanitized HTML, stripping scripts and handlers", :aggregate_failures do
    html = '<p>Hi</p><script>evil()</script><p onclick="x()">y</p>'
    stored = gql_data(run(html), "updatePageDescription", "puzzle")["pageDescriptionHtml"]
    expect(stored).to include("<p>Hi</p>")
    expect(stored).not_to include("script")
    expect(stored).not_to include("onclick")
  end

  it "requires the author" do
    result = run("<p>hi</p>", context: auth_context(create(:user)))
    expect(gql_errors(result).first["message"]).to eq("Puzzle not found")
  end

  it "requires authentication" do
    expect(gql_errors(run("<p>hi</p>", context: {})).first["message"]).to eq("Authentication required")
  end
end
