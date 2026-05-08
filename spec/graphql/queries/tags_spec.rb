require "rails_helper"

RSpec.describe "Query: tags", type: :graphql do
  let(:query) do
    <<~GQL
      query { tags { id name slug } }
    GQL
  end

  it "returns all tags ordered by name", :aggregate_failures do
    create(:tag, name: "Bravo")
    create(:tag, name: "Alpha")
    names = gql_data(execute_query(query), "tags").map { |t| t["name"] }
    expect(names).to eq(names.sort)
    expect(names).to include("Alpha", "Bravo")
  end

  it "returns an empty list when no tags exist" do
    result = execute_query(query)
    expect(gql_data(result, "tags")).to be_empty
  end
end
