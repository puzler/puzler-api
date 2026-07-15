require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe "#segments" do
    def segments_for(body)
      build(:comment, body:).segments
    end

    it "returns one text run for a body with no delimiters" do
      expect(segments_for("plain text")).to eq([ [ :text, "plain text" ] ])
    end

    it "alternates text and spoiler runs on balanced delimiters" do
      expect(segments_for("before ||hidden|| after")).to eq(
        [ [ :text, "before " ], [ :spoiler, "hidden" ], [ :text, " after" ] ]
      )
    end

    it "handles multiple spoiler runs" do
      expect(segments_for("||a|| mid ||b||")).to eq(
        [ [ :spoiler, "a" ], [ :text, " mid " ], [ :spoiler, "b" ] ]
      )
    end

    it "treats an unclosed trailing delimiter as literal text" do
      expect(segments_for("safe ||dangling")).to eq(
        [ [ :text, "safe " ], [ :text, "||dangling" ] ]
      )
    end

    it "never leaks an unclosed part after a closed spoiler" do
      expect(segments_for("||hidden|| tail ||oops")).to eq(
        [ [ :spoiler, "hidden" ], [ :text, " tail " ], [ :text, "||oops" ] ]
      )
    end

    it "collapses empty spoiler runs" do
      expect(segments_for("a |||| b")).to eq([ [ :text, "a " ], [ :text, " b" ] ])
    end

    it "returns the whole body as one spoiler run when flagged whole-comment" do
      comment = build(:comment, :spoiler, body: "all hidden")
      expect(comment.segments).to eq([ [ :spoiler, "all hidden" ] ])
    end
  end

  describe "#section_spoilers? / #spoilers?" do
    it "detects section spoilers", :aggregate_failures do
      expect(build(:comment, body: "||x||").section_spoilers?).to be(true)
      expect(build(:comment, body: "no marks").section_spoilers?).to be(false)
      expect(build(:comment, body: "unclosed ||").section_spoilers?).to be(false)
      expect(build(:comment, :spoiler).spoilers?).to be(true)
    end
  end

  describe "validation" do
    it "requires spoiler_marked_by when flagged" do
      comment = build(:comment, spoiler: true, spoiler_marked_by: nil)
      expect(comment).not_to be_valid
    end
  end

  describe "#spoilers_visible_to?" do
    let(:puzzle)  { create(:puzzle, :published) }
    let(:comment) { create(:comment, puzzle:) }

    it "allows the commenter" do
      expect(comment.spoilers_visible_to?(comment.user)).to be(true)
    end

    it "allows the puzzle author" do
      expect(comment.spoilers_visible_to?(puzzle.author)).to be(true)
    end

    it "allows an admin" do
      expect(comment.spoilers_visible_to?(create(:user, role: :admin))).to be(true)
    end

    it "allows a logged-in solver" do
      solver = create(:user)
      create(:puzzle_play, :solved, puzzle:, user: solver)
      expect(comment.spoilers_visible_to?(solver)).to be(true)
    end

    it "allows a guest solver via their actor" do
      create(:puzzle_play, :solved, puzzle:, user: nil, guest_token: "g-123")
      actor = Actor.new(guest_token: "g-123")
      expect(comment.spoilers_visible_to?(nil, actor:)).to be(true)
    end

    it "denies a logged-in non-solver" do
      expect(comment.spoilers_visible_to?(create(:user))).to be(false)
    end

    it "denies an anonymous viewer" do
      expect(comment.spoilers_visible_to?(nil)).to be(false)
    end
  end
end
