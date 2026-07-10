require "rails_helper"

RSpec.describe "Collection gate mutations", type: :graphql do
  let(:author) { create(:user) }
  let(:collection) { create(:collection, author:, visibility: :public, mode: :unordered) }

  describe "updateCollectionEntry" do
    let(:mutation) do
      <<~GQL
        mutation($c: ID!, $e: ID!, $g: CollectionEntryGatesInput!) {
          updateCollectionEntry(input: { collectionId: $c, entryId: $e, gates: $g }) {
            collection { entries { id gated hidden finale } }
            errors
          }
        }
      GQL
    end
    let(:entry) do
      create(:collection_entry, collection:,
        puzzle: create(:puzzle, author:, status: :published, visibility: :public))
    end

    def update(gates, context: auth_context(author))
      execute_query(mutation, variables: { c: collection.id, e: entry.id, g: gates }, context:)
    end

    it "sets and clears a codeword gate", :aggregate_failures do
      data = gql_data(update({ codeword: "open sesame" }), "updateCollectionEntry", "collection")
      expect(data["entries"].first["gated"]).to be(true)
      expect(entry.reload.codeword_matches?(" OPEN SESAME ")).to be(true)
      cleared = gql_data(update({ codeword: "" }), "updateCollectionEntry", "collection")
      expect(cleared["entries"].first["gated"]).to be(false)
    end

    it "sets finale, and hidden only alongside a codeword", :aggregate_failures do
      expect(gql_data(update({ finale: true }), "updateCollectionEntry", "collection")["entries"].first["finale"]).to be(true)
      expect(gql_data(update({ hidden: true }), "updateCollectionEntry")["errors"].first).to match(/hidden/i)
      data = gql_data(update({ hidden: true, codeword: "shh" }), "updateCollectionEntry", "collection")
      expect(data["entries"].first["hidden"]).to be(true)
    end

    it "requires the collection's author" do
      result = update({ codeword: "x" }, context: auth_context(create(:user)))
      expect(gql_errors(result).first["message"]).to eq("Collection not found")
    end

    it "schedules and clears a release time", :aggregate_failures do
      moment = 2.days.from_now.change(usec: 0)
      gql_data(update({ releasedAt: moment.iso8601 }), "updateCollectionEntry")
      expect(entry.reload).to have_attributes(released_at: moment, released?: false)
      gql_data(update({ releasedAt: nil }), "updateCollectionEntry")
      expect(entry.reload.released?).to be(true)
    end
  end

  describe "submitCollectionCodeword" do
    let(:mutation) do
      <<~GQL
        mutation($c: ID!, $g: String!, $t: String) {
          submitCollectionCodeword(input: { collectionId: $c, guess: $g, shareToken: $t }) {
            matched
            collection { entries { id locked storyPage { bodyHtml } storyTitle } }
            errors
          }
        }
      GQL
    end
    let(:solver) { create(:user) }
    let(:gated_story) do
      story = create(:story_page, author:, title: "Secret Chapter", body_html: "<p>Treasure.</p>")
      create(:collection_entry, collection:, entryable: story, position: 5, codeword: "raven")
    end

    def submit(guess, context: auth_context(solver), token: nil)
      gated_story
      result = execute_query(mutation, variables: { c: collection.id, g: guess, t: token }, context:)
      gql_data(result, "submitCollectionCodeword")
    end

    def story_state(data)
      data["collection"]["entries"].find { |e| e["id"] == gated_story.id.to_s }
    end

    it "unlocks matching entries for the actor, normalized", :aggregate_failures do
      opened = story_state(submit("  RAVEN "))
      expect(opened["locked"]).to be(false)
      expect(opened["storyPage"]["bodyHtml"]).to include("Treasure")
      expect(gated_story.reload.unlocked_by?(Actor.new(user: solver))).to be(true)
    end

    it "reports a miss without unlocking anything", :aggregate_failures do
      data = submit("wrong")
      expect(data["matched"]).to be(false)
      expect(story_state(data)).to include("locked" => true, "storyPage" => nil, "storyTitle" => "Secret Chapter")
    end

    it "unlocks for guests via their token", :aggregate_failures do
      expect(submit("raven", context: { guest_token: "guest-xyz" })["matched"]).to be(true)
      expect(gated_story.unlocked_by?(Actor.new(guest_token: "guest-xyz"))).to be(true)
    end

    it "works on unlisted collections reached by share token", :aggregate_failures do
      collection.update!(visibility: :unlisted)
      expect(submit("raven")["matched"]).to be(false)
      expect(submit("raven", token: collection.share_token)["matched"]).to be(true)
    end
  end
end
