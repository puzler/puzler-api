require "rails_helper"

RSpec.describe "Collection story entries", type: :graphql do
  let(:user) { create(:user) }
  let(:collection) { create(:collection, author: user) }
  let(:puzzle) { create(:puzzle, author: user, status: :published, visibility: :public) }

  def add_story(title: "Chapter", context: auth_context(user))
    m = <<~GQL
      mutation($c: ID!, $t: String) {
        addStoryPageToCollection(input: { collectionId: $c, title: $t }) {
          storyPage { id title }
          collection { entries { id entryType position } }
          errors
        }
      }
    GQL
    execute_query(m, variables: { c: collection.id, t: title }, context: context)
  end

  describe "addStoryPageToCollection" do
    it "creates the page at the end of the entry list", :aggregate_failures do
      create(:collection_entry, collection:, puzzle:, position: 0)
      data = gql_data(add_story, "addStoryPageToCollection")
      expect(data["storyPage"]["title"]).to eq("Chapter")
      expect(data["collection"]["entries"].map { |e| e["entryType"] }).to eq(%w[Puzzle StoryPage])
      expect(StoryPage.last.author_id).to eq(user.id)
    end

    it "requires the collection's author" do
      result = add_story(context: auth_context(create(:user)))
      expect(gql_errors(result).first["message"]).to eq("Collection not found")
    end
  end

  describe "updateStoryPage" do
    let(:story) { create(:story_page, author: user, title: "Old") }
    let(:mutation) do
      <<~GQL
        mutation($id: ID!, $t: String, $h: String) {
          updateStoryPage(input: { id: $id, title: $t, html: $h }) {
            storyPage { id title bodyHtml }
            errors
          }
        }
      GQL
    end

    def update(vars, context: auth_context(user))
      execute_query(mutation, variables: { id: story.id, **vars }, context: context)
    end

    it "updates the title and stores sanitized HTML", :aggregate_failures do
      data = gql_data(update({ t: "New", h: '<p>Hi</p><script>x()</script>' }), "updateStoryPage", "storyPage")
      expect(data["title"]).to eq("New")
      expect(data["bodyHtml"]).to include("<p>Hi</p>")
      expect(data["bodyHtml"]).not_to include("script")
    end

    it "clears the title with an empty string and leaves the body alone", :aggregate_failures do
      story.update!(body_html: "<p>Keep</p>")
      data = gql_data(update({ t: "" }), "updateStoryPage", "storyPage")
      expect(data["title"]).to be_nil
      expect(data["bodyHtml"]).to eq("<p>Keep</p>")
    end

    it "requires the story page's author" do
      result = update({ t: "Hacked" }, context: auth_context(create(:user)))
      expect(gql_errors(result).first["message"]).to eq("Story page not found")
    end
  end

  describe "removeCollectionEntry" do
    let(:mutation) do
      <<~GQL
        mutation($c: ID!, $e: ID!) {
          removeCollectionEntry(input: { collectionId: $c, entryId: $e }) {
            collection { entries { id } }
            errors
          }
        }
      GQL
    end

    def remove(entry)
      execute_query(mutation, variables: { c: collection.id, e: entry.id }, context: auth_context(user))
    end

    it "unlinks a puzzle entry without touching the puzzle", :aggregate_failures do
      entry = create(:collection_entry, collection:, puzzle:)
      expect { remove(entry) }.not_to change(Puzzle, :count)
      expect(collection.entries.count).to eq(0)
    end

    it "destroys a story page with its entry", :aggregate_failures do
      story = create(:story_page, author: user)
      entry = create(:collection_entry, collection:, entryable: story)
      expect { remove(entry) }.to change(StoryPage, :count).by(-1)
      expect(CollectionEntry.exists?(entry.id)).to be(false)
    end
  end

  describe "reorderCollectionEntries" do
    let(:mutation) do
      <<~GQL
        mutation($c: ID!, $ids: [ID!]!) {
          reorderCollectionEntries(input: { collectionId: $c, orderedEntryIds: $ids }) {
            collection { entries { id } }
            errors
          }
        }
      GQL
    end

    def reorder(ids)
      result = execute_query(mutation, variables: { c: collection.id, ids: }, context: auth_context(user))
      gql_data(result, "reorderCollectionEntries", "collection")
    end

    it "orders puzzles and story pages in one sequence" do
      puzzle_entry = create(:collection_entry, collection:, puzzle:, position: 0)
      story_entry = create(:collection_entry, collection:, entryable: create(:story_page, author: user), position: 1)
      wanted = [ story_entry.id.to_s, puzzle_entry.id.to_s ]
      expect(reorder(wanted)["entries"].map { |e| e["id"] }).to eq(wanted)
    end
  end

  describe "CollectionType#entries visibility" do
    let(:query) do
      <<~GQL
        query($id: ID!) {
          collection(id: $id) {
            entries { entryType puzzle { id } storyPage { id title bodyHtml } }
          }
        }
      GQL
    end

    before do
      collection.update!(visibility: :public)
      create(:collection_entry, collection:, puzzle:, position: 0)
      create(:collection_entry, collection:, entryable: create(:story_page, author: user, title: "Interlude"),
        position: 1)
      create(:collection_entry, collection:, puzzle: create(:puzzle, author: user, status: :draft), position: 2)
    end

    def entries_for(context)
      gql_data(execute_query(query, variables: { id: collection.id }, context:), "collection")["entries"]
    end

    it "hides non-visible puzzles from non-authors but always shows story pages", :aggregate_failures do
      viewer = entries_for({})
      expect(viewer.map { |e| e["entryType"] }).to eq(%w[Puzzle StoryPage])
      expect(viewer.last["storyPage"]["title"]).to eq("Interlude")
    end

    it "shows authors everything, drafts included" do
      expect(entries_for(auth_context(user)).map { |e| e["entryType"] }).to eq(%w[Puzzle StoryPage Puzzle])
    end
  end
end
