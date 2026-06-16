require "rails_helper"

RSpec.describe Folder, type: :model do
  it "leaves its puzzles intact (just unfiled) when destroyed", :aggregate_failures do
    folder = create(:folder)
    puzzle = create(:puzzle, author: folder.author, folder:)
    expect { folder.destroy }.not_to change(Puzzle, :count)
    expect(puzzle.reload.folder_id).to be_nil
  end

  it "leaves its collections intact and orphans children when destroyed" do
    parent = create(:folder)
    child = create(:folder, author: parent.author, parent:)
    collection = create(:collection, author: parent.author, folder: parent)
    parent.destroy
    # reload would raise if either record had been destroyed rather than orphaned
    expect([ collection.reload.folder_id, child.reload.parent_id ]).to eq([ nil, nil ])
  end

  describe "cycle prevention" do
    let(:author) { create(:user) }
    let(:parent) { create(:folder, author:) }
    let(:child)  { create(:folder, author:, parent:) }

    it "rejects making a folder its own parent" do
      parent.parent = parent
      expect(parent).not_to be_valid
    end

    it "rejects reparenting a folder under one of its descendants", :aggregate_failures do
      grandchild = create(:folder, author:, parent: child)
      parent.parent = grandchild
      expect(parent).not_to be_valid
      expect(parent.errors[:parent_id]).to be_present
    end

    it "allows a valid reparent" do
      other = create(:folder, author:)
      child.parent = other
      expect(child).to be_valid
    end
  end

  describe "#descendant_ids" do
    it "collects every nested folder id", :aggregate_failures do
      author = create(:user)
      root = create(:folder, author:)
      a = create(:folder, author:, parent: root)
      b = create(:folder, author:, parent: a)
      expect(root.descendant_ids).to contain_exactly(a.id, b.id)
    end
  end
end
