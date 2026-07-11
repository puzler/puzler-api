require "rails_helper"

RSpec.describe CollectionGate do
  let(:collection) { create(:collection, mode: :sequence, kind: :hunt) }
  let(:actor) { Actor.new(user: create(:user)) }

  # Opening puzzle, story interlude, closing puzzle.
  let(:layout) do
    author = collection.author
    [
      create(:collection_entry, collection:,
        puzzle: create(:puzzle, author:, status: :published, visibility: :public), position: 0),
      create(:collection_entry, collection:,
        entryable: create(:story_page, author:), position: 1),
      create(:collection_entry, collection:,
        puzzle: create(:puzzle, author:, status: :published, visibility: :public), position: 2)
    ]
  end

  def opening = layout[0]
  def interlude = layout[1]
  def closing = layout[2]

  def resolve(for_actor: actor, author_view: false, competition_run: nil)
    layout
    described_class.new(collection.reload, actor: for_actor, author_view:, competition_run:)
                   .call(collection.entries.to_a)
  end

  def solve!(entry, by: actor)
    create(:puzzle_play, puzzle: entry.entryable, is_solved: true, **by.owner_attrs)
  end

  it "locks everything past the first unsolved puzzle in sequence mode" do
    expect(resolve.map(&:locked)).to eq([ false, true, true ])
  end

  it "reveals the story and next puzzle once the first is solved", :aggregate_failures do
    solve!(opening)
    states = resolve
    expect(states.map(&:locked)).to eq([ false, false, false ])
    expect(states.first.solved).to be(true)
  end

  it "opens everything in unordered mode with no gates" do
    collection.update!(mode: :unordered)
    expect(resolve.map(&:locked)).to eq([ false, false, false ])
  end

  it "treats a viewer with no actor as having no progress" do
    expect(resolve(for_actor: nil).map(&:locked)).to eq([ false, true, true ])
  end

  it "shows authors everything unlocked" do
    expect(resolve(author_view: true).map(&:locked)).to eq([ false, false, false ])
  end

  describe "codeword gates" do
    before do
      collection.update!(mode: :unordered)
      interlude.update!(codeword: "  FogGate ")
    end

    it "locks a gated entry until the codeword is entered, normalized", :aggregate_failures do
      expect(resolve[1].locked).to be(true)
      interlude.unlocks.create!(user: actor.user)
      expect(resolve[1].locked).to be(false)
    end

    it "keeps gated entries locked for other actors" do
      interlude.unlocks.create!(guest_token: "someone-else")
      expect(resolve[1].locked).to be(true)
    end
  end

  describe "hidden entries" do
    before do
      collection.update!(mode: :unordered)
      interlude.update!(codeword: "secret", hidden: true)
    end

    it "omits hidden entries entirely until unlocked", :aggregate_failures do
      expect(resolve.map(&:id)).to eq([ opening.id, closing.id ])
      interlude.unlocks.create!(user: actor.user)
      expect(resolve.map(&:id)).to eq([ opening.id, interlude.id, closing.id ])
    end

    it "keeps hidden entries visible to the author" do
      expect(resolve(author_view: true).map(&:id)).to include(interlude.id)
    end
  end

  describe "finale entries" do
    before do
      collection.update!(mode: :unordered)
      closing.update!(finale: true)
    end

    it "locks the finale until every other puzzle is solved", :aggregate_failures do
      expect(resolve.map(&:locked)).to eq([ false, false, true ])
      solve!(opening)
      expect(resolve.map(&:locked)).to eq([ false, false, false ])
    end

    it "never unlocks a finale in an all-finale collection (nothing to earn it with)" do
      opening.update!(finale: true)
      expect(resolve.map(&:locked)).to eq([ true, false, true ])
    end
  end

  describe "scheduled release" do
    before do
      collection.update!(mode: :sequence)
      interlude.update!(released_at: 1.day.from_now)
    end

    it "omits unreleased entries without blocking the sequence", :aggregate_failures do
      solve!(opening)
      expect(resolve.map(&:id)).to eq([ opening.id, closing.id ])
      expect(resolve.last.locked).to be(false)
    end

    it "shows released and author views in full", :aggregate_failures do
      interlude.update!(released_at: 1.hour.ago)
      expect(resolve.map(&:id)).to include(interlude.id)
      interlude.update!(released_at: 1.day.from_now)
      expect(resolve(author_view: true).map(&:id)).to include(interlude.id)
    end
  end

  it "resolves solve state for guest actors via their token", :aggregate_failures do
    guest = Actor.new(guest_token: "guest-abc")
    expect(resolve(for_actor: guest).map(&:locked)).to eq([ false, true, true ])
    solve!(opening, by: guest)
    expect(resolve(for_actor: guest).map(&:locked)).to eq([ false, false, false ])
  end

  describe "basic kind" do
    before { collection.update!(kind: :basic) }

    def arm_dormant_gates
      interlude.update!(codeword: "secret", hidden: true)
      closing.update!(finale: true)
      solve!(opening)
    end

    it "honors sequence, ignores dormant gates, and hides story pages", :aggregate_failures do
      arm_dormant_gates
      expect(resolve.map(&:id)).to eq([ opening.id, closing.id ])
      expect(resolve.map(&:locked)).to eq([ false, false ])
      expect(resolve(author_view: true).map(&:id)).to include(interlude.id)
    end

    it "still honors scheduled release" do
      interlude.update!(released_at: 1.day.from_now)
      expect(resolve.map(&:id)).to eq([ opening.id, closing.id ])
    end
  end

  describe "competition kind" do
    before { collection.update!(kind: :competition, mode: :sequence) }

    it "locks all puzzles for viewers without a run, hiding story pages", :aggregate_failures do
      solve!(opening)
      expect(resolve.map(&:id)).to eq([ opening.id, closing.id ])
      expect(resolve.map(&:locked)).to eq([ true, true ])
      expect(resolve.map(&:solved)).to eq([ false, false ])
    end

    it "opens the puzzles once the viewer has a run, but never surfaces solves", :aggregate_failures do
      solve!(opening)
      states = resolve(competition_run: Object.new)
      expect(states.map(&:locked)).to eq([ false, false ])
      expect(states.map(&:solved)).to eq([ false, false ])
    end

    it "hides unreleased entries and shows authors everything", :aggregate_failures do
      interlude.update!(released_at: 1.day.from_now)
      expect(resolve.map(&:id)).to eq([ opening.id, closing.id ])
      expect(resolve(author_view: true).map(&:locked)).to eq([ false, false, false ])
    end
  end
end
