require "rails_helper"

RSpec.describe "Puzzle description-page GraphQL fields", type: :graphql do
  let(:query) do
    <<~GQL
      query($id: ID!) {
        puzzle(id: $id) {
          sudokupadUrl
          sudokupadIncludesSolution
          commentsRequireSolveEffective
          viewerHasSolved
          comments { id commenterSolved isAuthor }
        }
      }
    GQL
  end

  def fetch(puzzle, context: {})
    gql_data(execute_query(query, variables: { id: puzzle.id }, context: context), "puzzle")
  end

  def count_queries
    count = 0
    sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      count += 1 unless payload[:name] == "SCHEMA" || payload[:sql].match?(/^\s*(BEGIN|COMMIT|SAVEPOINT|RELEASE)/i)
    end
    yield
    count
  ensure
    ActiveSupport::Notifications.unsubscribe(sub)
  end

  describe "sudokupadUrl gating" do
    let(:author) { create(:user) }
    let(:puzzle) do
      create(:puzzle, :published, author: author,
        sudokupad_url: "https://sudokupad.app/plain", sudokupad_solution_url: "https://sudokupad.app/sol")
    end

    it "serves the solution link when the author opted in", :aggregate_failures do
      expect(fetch(puzzle)["sudokupadUrl"]).to eq("https://sudokupad.app/sol")
      expect(fetch(puzzle)["sudokupadIncludesSolution"]).to be(true)
    end

    it "serves the solution-less link when the author opted out", :aggregate_failures do
      author.update!(include_solution_in_sudokupad_export: false)
      expect(fetch(puzzle)["sudokupadUrl"]).to eq("https://sudokupad.app/plain")
      expect(fetch(puzzle)["sudokupadIncludesSolution"]).to be(false)
    end

    it "is null when no link was built (e.g. a non-square puzzle)" do
      expect(fetch(create(:puzzle, :published, author: author))["sudokupadUrl"]).to be_nil
    end
  end

  describe "comment badges" do
    let(:author) { create(:user) }
    let(:solver) { create(:user) }
    let(:stranger) { create(:user) }
    let(:puzzle) { create(:puzzle, :published, author: author) }

    before do
      create(:puzzle_play, :solved, puzzle: puzzle, user: solver)
      [ author, solver, stranger ].each { |u| create(:comment, puzzle: puzzle, user: u) }
    end

    def badge(user)
      id = Comment.find_by(puzzle: puzzle, user: user).id.to_s
      fetch(puzzle)["comments"].find { |c| c["id"] == id }
    end

    it "flags the puzzle author" do
      expect(badge(author)).to include("isAuthor" => true)
    end

    it "flags a confirmed solver" do
      expect(badge(solver)).to include("commenterSolved" => true)
    end

    it "leaves a stranger unflagged" do
      expect(badge(stranger)).to include("commenterSolved" => false, "isAuthor" => false)
    end

    it "resolves badges without N+1 as comments grow" do
      base = count_queries { fetch(puzzle) }
      create_list(:comment, 4, puzzle: puzzle)
      expect(count_queries { fetch(puzzle) }).to eq(base)
    end
  end

  describe "viewerHasSolved" do
    let(:viewer) { create(:user) }
    let(:puzzle) { create(:puzzle, :published) }

    it "is false before the viewer solves" do
      expect(fetch(puzzle, context: auth_context(viewer))["viewerHasSolved"]).to be(false)
    end

    it "is true after the viewer solves" do
      create(:puzzle_play, :solved, puzzle: puzzle, user: viewer)
      expect(fetch(puzzle, context: auth_context(viewer))["viewerHasSolved"]).to be(true)
    end
  end
end
