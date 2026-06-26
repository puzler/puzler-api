require "rails_helper"

RSpec.describe "Play sharing mutations", type: :graphql do
  let(:owner) { create(:user) }
  let(:joiner) { create(:user) }
  let(:play) { create(:puzzle_play, user: owner) }

  describe "generatePlayShareToken" do
    let(:mutation) do
      <<~GQL
        mutation($id: ID!, $single: Boolean) {
          generatePlayShareToken(input: { puzzlePlayId: $id, singleUse: $single }) {
            shareToken { token singleUse consumed }
            errors
          }
        }
      GQL
    end

    it "lets the owner create a token", :aggregate_failures do
      result = execute_query(mutation, variables: { id: play.id, single: false }, context: auth_context(owner))
      token = gql_data(result, "generatePlayShareToken", "shareToken")
      expect(token["token"]).to be_present
      expect(token["singleUse"]).to be false
    end

    it "reuses the active token across calls" do
      a = execute_query(mutation, variables: { id: play.id }, context: auth_context(owner))
      b = execute_query(mutation, variables: { id: play.id }, context: auth_context(owner))
      expect(gql_data(a, "generatePlayShareToken", "shareToken", "token"))
        .to eq(gql_data(b, "generatePlayShareToken", "shareToken", "token"))
    end

    it "rejects a non-owner" do
      result = execute_query(mutation, variables: { id: play.id }, context: auth_context(joiner))
      expect(gql_errors(result).first["message"]).to eq("Not authorized")
    end
  end

  describe "joinPlaySession" do
    let(:mutation) do
      <<~GQL
        mutation($token: String!) {
          joinPlaySession(input: { token: $token }) { puzzlePlay { id } errors }
        }
      GQL
    end

    it "adds the joiner as a participant", :aggregate_failures do
      token = create(:puzzle_play_share_token, puzzle_play: play, created_by: owner)
      result = execute_query(mutation, variables: { token: token.token }, context: auth_context(joiner))
      expect(gql_data(result, "joinPlaySession", "puzzlePlay", "id")).to eq(play.id.to_s)
      expect(play.participants.exists?(user: joiner)).to be true
    end

    it "consumes a single-use token and blocks a second joiner" do
      token = create(:puzzle_play_share_token, puzzle_play: play, created_by: owner, single_use: true)
      execute_query(mutation, variables: { token: token.token }, context: auth_context(joiner))
      result = execute_query(mutation, variables: { token: token.token }, context: auth_context(create(:user)))
      expect(gql_errors(result).first["message"]).to eq("This share link has already been used")
    end

    it "rejects a revoked token" do
      token = create(:puzzle_play_share_token, puzzle_play: play, created_by: owner, revoked_at: Time.current)
      result = execute_query(mutation, variables: { token: token.token }, context: auth_context(joiner))
      expect(gql_errors(result).first["message"]).to eq("This share link was revoked")
    end
  end

  describe "revokePlaySession" do
    let(:mutation) do
      <<~GQL
        mutation($id: ID!) { revokePlaySession(input: { puzzlePlayId: $id }) { errors } }
      GQL
    end

    it "revokes tokens and removes collaborators", :aggregate_failures do
      token = create(:puzzle_play_share_token, puzzle_play: play, created_by: owner)
      create(:puzzle_play_participant, puzzle_play: play, user: joiner, added_via_token: token)
      execute_query(mutation, variables: { id: play.id }, context: auth_context(owner))
      expect(play.participants.count).to eq(0)
      expect(token.reload.revoked_at).to be_present
    end

    it "rejects a non-owner" do
      result = execute_query(mutation, variables: { id: play.id }, context: auth_context(joiner))
      expect(gql_errors(result).first["message"]).to eq("Not authorized")
    end
  end

  describe "guest collaboration" do
    describe "generatePlayShareToken promotes a guest host" do
      let(:published) { create(:puzzle, :published) }
      let(:mutation) do
        <<~GQL
          mutation($puzzleId: ID, $seed: JSON) {
            generatePlayShareToken(input: { puzzleId: $puzzleId, seed: $seed }) {
              puzzlePlay { id }
              shareToken { token }
              errors
            }
          }
        GQL
      end

      it "creates a guest-hosted play seeded from the local snapshot", :aggregate_failures do
        seed = { "cellState" => { "r1c1" => { "digit" => 5 } }, "progressState" => { "timeElapsedSeconds" => 12 } }
        result = execute_query(mutation, variables: { puzzleId: published.id, seed: seed }, context: guest_context("g_host"))
        expect(gql_data(result, "generatePlayShareToken", "shareToken", "token")).to be_present
        promoted = PuzzlePlay.find(gql_data(result, "generatePlayShareToken", "puzzlePlay", "id"))
        expect(promoted).to have_attributes(guest_token: "g_host", cell_state: { "r1c1" => { "digit" => 5 } })
      end

      it "reuses the promoted play on a second share" do
        a = execute_query(mutation, variables: { puzzleId: published.id }, context: guest_context("g_host"))
        b = execute_query(mutation, variables: { puzzleId: published.id }, context: guest_context("g_host"))
        expect(gql_data(a, "generatePlayShareToken", "puzzlePlay", "id"))
          .to eq(gql_data(b, "generatePlayShareToken", "puzzlePlay", "id"))
      end
    end

    describe "joinPlaySession across identities" do
      let(:join) do
        <<~GQL
          mutation($token: String!) {
            joinPlaySession(input: { token: $token }) { puzzlePlay { id } errors }
          }
        GQL
      end

      it "lets a guest join a user-owned play", :aggregate_failures do
        token = create(:puzzle_play_share_token, puzzle_play: play, created_by: owner)
        result = execute_query(join, variables: { token: token.token }, context: guest_context("g_joiner"))
        expect(gql_data(result, "joinPlaySession", "puzzlePlay", "id")).to eq(play.id.to_s)
        expect(play.participants.exists?(guest_token: "g_joiner")).to be true
      end

      it "lets a user join a guest-owned play" do
        guest_play = create(:puzzle_play, user: nil, guest_token: "g_host")
        token = create(:puzzle_play_share_token, puzzle_play: guest_play, created_by: nil, created_by_guest_token: "g_host")
        execute_query(join, variables: { token: token.token }, context: auth_context(joiner))
        expect(guest_play.participants.exists?(user: joiner)).to be true
      end

      it "consumes a single-use token claimed by a guest" do
        token = create(:puzzle_play_share_token, puzzle_play: play, created_by: owner, single_use: true)
        execute_query(join, variables: { token: token.token }, context: guest_context("g_first"))
        result = execute_query(join, variables: { token: token.token }, context: guest_context("g_second"))
        expect(gql_errors(result).first["message"]).to eq("This share link has already been used")
      end

      it "rejects a blocked guest" do
        token = create(:puzzle_play_share_token, puzzle_play: play, created_by: owner)
        play.blocked_actors.create!(guest_token: "g_blocked")
        result = execute_query(join, variables: { token: token.token }, context: guest_context("g_blocked"))
        expect(gql_errors(result).first["message"]).to eq("You've been removed from this session")
      end
    end
  end
end
