require "rails_helper"

RSpec.describe CollectionEntry, type: :model do
  let(:collection) { create(:collection) }
  let(:puzzle) { create(:puzzle, author: collection.author) }
  let(:story) { create(:story_page, author: collection.author) }

  it "holds puzzles and story pages in one position order", :aggregate_failures do
    create(:collection_entry, collection:, entryable: story, position: 1)
    create(:collection_entry, collection:, puzzle:, position: 0)

    expect(collection.entries.map(&:entryable)).to eq([ puzzle, story ])
    expect(collection.puzzles).to eq([ puzzle ])
  end

  it "rejects the same entryable twice in one collection but allows it across types", :aggregate_failures do
    create(:collection_entry, collection:, puzzle:)

    expect(build(:collection_entry, collection:, puzzle:)).not_to be_valid
    # Same numeric id under a different type is a different record.
    same_id_story = create(:story_page, id: puzzle.id)
    expect(build(:collection_entry, collection:, entryable: same_id_story)).to be_valid
  end

  it "destroying a collection removes entries but not the entryables", :aggregate_failures do
    create(:collection_entry, collection:, puzzle:)
    create(:collection_entry, collection:, entryable: story)

    expect { collection.destroy! }.to change(described_class, :count).by(-2)
    expect([ Puzzle.exists?(puzzle.id), StoryPage.exists?(story.id) ]).to all(be(true))
  end
end
