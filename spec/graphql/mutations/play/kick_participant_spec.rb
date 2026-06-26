require "rails_helper"

RSpec.describe "Mutation: kickParticipant", type: :graphql do
  let(:owner) { create(:user) }
  let(:joiner) { create(:user) }
  let(:play) { create(:puzzle_play, user: owner) }
  let(:mutation) do
    <<~GQL
      mutation($id: ID!, $actorId: String!, $block: Boolean) {
        kickParticipant(input: { puzzlePlayId: $id, actorId: $actorId, block: $block }) {
          success
          errors
        }
      }
    GQL
  end

  it "lets the host remove a user participant", :aggregate_failures do
    create(:puzzle_play_participant, puzzle_play: play, user: joiner)
    result = execute_query(mutation, variables: { id: play.id, actorId: "user:#{joiner.id}" }, context: auth_context(owner))
    expect(gql_data(result, "kickParticipant", "success")).to be true
    expect(play.participants.exists?(user: joiner)).to be false
  end

  it "removes and blocks a guest when block is true", :aggregate_failures do
    create(:puzzle_play_participant, :guest, puzzle_play: play, guest_token: "g_x")
    execute_query(mutation, variables: { id: play.id, actorId: "guest:g_x", block: true }, context: auth_context(owner))
    expect(play.participants.exists?(guest_token: "g_x")).to be false
    expect(play.blocked?(Actor.new(guest_token: "g_x"))).to be true
  end

  it "rejects a non-host" do
    result = execute_query(mutation, variables: { id: play.id, actorId: "user:#{owner.id}" }, context: auth_context(joiner))
    expect(gql_errors(result).first["message"]).to eq("Not authorized")
  end

  it "refuses to remove the host" do
    result = execute_query(mutation, variables: { id: play.id, actorId: "user:#{owner.id}" }, context: auth_context(owner))
    expect(gql_errors(result).first["message"]).to eq("Cannot remove the host")
  end
end
