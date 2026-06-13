require "rails_helper"

RSpec.describe Folder, type: :model do
  it "leaves its puzzles intact (just unfiled) when destroyed", :aggregate_failures do
    folder = create(:folder)
    puzzle = create(:puzzle, author: folder.author, folder:)
    expect { folder.destroy }.not_to change(Puzzle, :count)
    expect(puzzle.reload.folder_id).to be_nil
  end
end
