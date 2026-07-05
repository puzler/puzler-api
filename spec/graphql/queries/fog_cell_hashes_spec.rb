require "rails_helper"

RSpec.describe "Queries: publishedVersion.fogCellHashes", type: :graphql do
  let(:query) do
    <<~GQL
      query($id: ID!) {
        puzzle(id: $id) {
          publishedVersion { fogCellHashes solutionHash }
        }
      }
    GQL
  end
  let(:fog_definition) do
    {
      "formatVersion" => 4,
      "globals" => { "fog" => { "enabled" => true } },
      "constraints" => { "fogLights" => [ "r1c1" ] }
    }
  end

  # Gridless definitions keep the SudokuPad link builder a no-op (see the
  # puzzle_version factory note).
  def publish(puzzle, definition, solution: { "r0c0" => 5, "r0c1" => 3 })
    version = create(:puzzle_version, puzzle:, definition:, solution:)
    puzzle.update!(published_version: version)
    version
  end

  def fetch(puzzle, context: {})
    gql_data(execute_query(query, variables: { id: puzzle.id }, context: context), "puzzle", "publishedVersion")
  end

  # The salt is the public solutionHash, so the client can verify locally.
  it "returns per-cell hashes to guests when fog is enabled", :aggregate_failures do
    puzzle = create(:puzzle, :published)
    version = publish(puzzle, fog_definition)
    data = fetch(puzzle)
    expect(data["fogCellHashes"].keys).to contain_exactly("r0c0", "r0c1")
    expect(data["fogCellHashes"]["r0c0"]).to eq(Digest::SHA256.hexdigest("#{version.solution_hash}:r0c0:5"))
  end

  it "is null when fog is not enabled" do
    puzzle = create(:puzzle, :published)
    publish(puzzle, { "formatVersion" => 4, "globals" => { "fog" => {} } })
    expect(fetch(puzzle)["fogCellHashes"]).to be_nil
  end

  it "is null when the version has no solution" do
    puzzle = create(:puzzle, :published)
    publish(puzzle, fog_definition, solution: {})
    expect(fetch(puzzle)["fogCellHashes"]).to be_nil
  end
end
