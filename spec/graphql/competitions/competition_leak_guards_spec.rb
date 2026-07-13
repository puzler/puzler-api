require "rails_helper"

RSpec.describe "Competition leak guards", type: :graphql do
  let(:solver) { create(:user) }
  let(:collection) do
    create(:collection, visibility: :public, kind: :competition, time_limit_seconds: 1800)
  end
  let(:puzzle) do
    create(:puzzle, :published, visibility: :public).tap do |p|
      create(:collection_entry, collection:, puzzle: p)
    end
  end
  let!(:run) { create(:competition_run, collection:, user: solver) }

  def as_solver(query, variables)
    execute_query(query, variables:, context: auth_context(solver))
  end

  def play_mutations
    [
      "mutation($p: ID!) { submitSolution(input: { puzzleId: $p, cellState: {}, timeElapsedSeconds: 1 }) { solved } }",
      "mutation($p: ID!) { checkSolution(input: { puzzleId: $p, board: {} }) { result } }",
      "mutation($p: ID!) { revealSolveMessage(input: { puzzleId: $p, solutionHash: \"x\" }) { correct } }"
    ]
  end

  def hash_query
    "query($id: ID!) { puzzle(id: $id) { publishedVersion { solutionHash } } }"
  end

  it "rejects the normal play mutations while the run is active", :aggregate_failures do
    play_mutations.each do |mutation|
      expect(gql_errors(as_solver(mutation, { p: puzzle.id })).first["message"]).to match(/competition/i)
    end
  end

  it "withholds the solution hash while the run is active, for the solver only", :aggregate_failures do
    puzzle.update!(published_version: create(:puzzle_version, puzzle:, solution_hash: "abc123"))
    mine = gql_data(as_solver(hash_query, { id: puzzle.id }), "puzzle")
    expect(mine).to include("publishedVersion" => include("solutionHash" => nil))
    other = execute_query(hash_query, variables: { id: puzzle.id }, context: auth_context(create(:user)))
    expect(gql_data(other, "puzzle").dig("publishedVersion", "solutionHash")).to be_present
  end

  it "restores everything once the run ends", :aggregate_failures do
    puzzle.update!(published_version: create(:puzzle_version, puzzle:, solution_hash: "abc123"))
    run.update!(finished_at: Time.current)
    expect(gql_data(as_solver(hash_query, { id: puzzle.id }), "puzzle").dig("publishedVersion", "solutionHash")).to be_present
    check = "mutation($p: ID!) { checkSolution(input: { puzzleId: $p, board: {} }) { result } }"
    expect(gql_errors(as_solver(check, { p: puzzle.id }))).to be_empty
  end

  it "locks the contest terms once someone has competed" do
    m = "mutation($id: ID!) { updateCollection(input: { id: $id, attrs: { kind: BASIC } }) { errors } }"
    result = execute_query(m, variables: { id: collection.id }, context: auth_context(collection.author))
    expect(gql_data(result, "updateCollection")["errors"].first).to include('locked')
  end
end
