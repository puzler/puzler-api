require "rails_helper"

RSpec.describe CollectionGate do
  let(:collection) { create(:collection, mode: :sequence) }
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

  def resolve(for_actor: actor, author_view: false)
    layout
    described_class.new(collection.reload, actor: for_actor, author_view:).call(collection.entries.to_a)
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

  it "resolves solve state for guest actors via their token", :aggregate_failures do
    guest = Actor.new(guest_token: "guest-abc")
    expect(resolve(for_actor: guest).map(&:locked)).to eq([ false, true, true ])
    solve!(opening, by: guest)
    expect(resolve(for_actor: guest).map(&:locked)).to eq([ false, false, false ])
  end
end
