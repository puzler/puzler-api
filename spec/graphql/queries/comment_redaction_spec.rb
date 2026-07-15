require "rails_helper"

# Server-side spoiler redaction: spoiler text must never reach a viewer who
# has not solved the puzzle, on any path that serializes a comment.
RSpec.describe "Comment spoiler redaction", type: :graphql do
  let(:puzzle) { create(:puzzle, :published) }
  let!(:section_comment) { create(:comment, puzzle:, body: "safe ||the trick is X|| end") }
  let!(:whole_comment) { create(:comment, :spoiler, puzzle:, body: "everything hidden") }

  let(:query) do
    <<~GQL
      query($id: ID!) {
        puzzle(id: $id) {
          comments {
            id body isSpoiler spoilersRedacted spoilerMarkedBySetter canDelete canMarkSpoiler
            segments { spoiler redacted text }
          }
        }
      }
    GQL
  end

  def comments_for(context)
    result = execute_query(query, variables: { id: puzzle.id }, context:)
    gql_data(result, "puzzle", "comments").index_by { |c| c["id"].to_i }
  end

  context "when the viewer is an anonymous non-solver" do
    it "never serializes spoiler text", :aggregate_failures do
      json = comments_for({}).to_json
      expect(json).not_to include("the trick is X")
      expect(json).not_to include("everything hidden")
    end

    it "redacts section spoilers to a marker", :aggregate_failures do
      section = comments_for({})[section_comment.id]
      expect(section["body"]).to eq("safe [spoiler] end")
      expect(section["segments"][1]).to eq({ "spoiler" => true, "redacted" => true, "text" => nil })
      expect(section["segments"].values_at(0, 2).map { |s| s["text"] }).to eq([ "safe ", " end" ])
    end

    it "redacts whole-comment spoilers entirely", :aggregate_failures do
      whole = comments_for({})[whole_comment.id]
      expect(whole["body"]).to eq("")
      expect(whole["segments"]).to eq([ { "spoiler" => true, "redacted" => true, "text" => nil } ])
      expect(whole.values_at("spoilersRedacted", "canDelete", "canMarkSpoiler")).to eq([ true, false, false ])
    end
  end

  context "when the viewer is a logged-in non-solver" do
    it "withholds spoiler text" do
      json = comments_for(auth_context(create(:user))).to_json
      expect(json).not_to include("the trick is X")
    end
  end

  context "when the viewer has solved the puzzle" do
    let(:solver) { create(:user) }

    before { create(:puzzle_play, :solved, puzzle:, user: solver) }

    it "reveals spoiler text but keeps it flagged", :aggregate_failures do
      section = comments_for(auth_context(solver))[section_comment.id]
      expect(section["segments"][1]).to eq({ "spoiler" => true, "redacted" => false, "text" => "the trick is X" })
      expect(section["spoilersRedacted"]).to be(false)
      expect(section["body"]).to eq("safe ||the trick is X|| end")
    end
  end

  context "when a guest solved the puzzle" do
    before { create(:puzzle_play, :solved, puzzle:, user: nil, guest_token: "guest-42") }

    it "reveals spoiler text via the guest token" do
      section = comments_for(guest_context("guest-42"))[section_comment.id]
      expect(section["segments"][1]["text"]).to eq("the trick is X")
    end
  end

  context "when the viewer wrote the comment but has not solved" do
    it "always shows them their own spoiler content", :aggregate_failures do
      mine = comments_for(auth_context(whole_comment.user))[whole_comment.id]
      expect(mine["body"]).to eq("everything hidden")
      expect(mine["spoilersRedacted"]).to be(false)
      expect(mine["canDelete"]).to be(true)
      expect(mine["canMarkSpoiler"]).to be(true)
    end

    it "still hides other people's spoilers on the same puzzle" do
      other = comments_for(auth_context(whole_comment.user))[section_comment.id]
      expect(other["segments"][1]["redacted"]).to be(true)
    end
  end

  context "when the viewer authored the puzzle" do
    it "reveals spoilers and grants moderation", :aggregate_failures do
      section = comments_for(auth_context(puzzle.author))[section_comment.id]
      expect(section["segments"][1]["text"]).to eq("the trick is X")
      expect(section["canMarkSpoiler"]).to be(true)
      expect(section["canDelete"]).to be(false)
    end
  end

  context "when the viewer is an admin" do
    it "reveals spoilers" do
      admin = create(:user, role: :admin)
      expect(comments_for(auth_context(admin))[whole_comment.id]["body"]).to eq("everything hidden")
    end
  end

  context "when comments surface through the profile activity feed" do
    let(:profile_query) do
      <<~GQL
        query($username: String!) {
          user(username: $username) { activity { comment { body } } }
        }
      GQL
    end

    it "redacts the plain body there too", :aggregate_failures do
      whole_comment.user.update!(show_activity: true)
      result = execute_query(profile_query, variables: { username: whole_comment.user.username }, context: {})
      bodies = gql_data(result, "user", "activity").filter_map { |a| a.dig("comment", "body") }
      expect(bodies).not_to be_empty
      expect(bodies.join).not_to include("everything hidden")
    end
  end
end
