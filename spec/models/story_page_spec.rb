require "rails_helper"

RSpec.describe StoryPage, type: :model do
  it "allows a blank title but caps its length", :aggregate_failures do
    expect(build(:story_page, title: nil)).to be_valid
    expect(build(:story_page, title: "x" * 101)).not_to be_valid
  end

  it "destroying a story page removes its collection entries" do
    story = create(:story_page)
    create(:collection_entry, entryable: story)

    expect { story.destroy! }.to change(CollectionEntry, :count).by(-1)
  end

  it_behaves_like "a model with a rich description" do
    let(:record) { create(:story_page) }
  end
end
