require "rails_helper"

RSpec.describe "Mutation: setCommentSpoiler", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($id: ID!, $spoiler: Boolean!) {
        setCommentSpoiler(input: { id: $id, spoiler: $spoiler }) {
          comment { id isSpoiler spoilerMarkedBySetter }
          errors
        }
      }
    GQL
  end

  let(:puzzle)  { create(:puzzle, :published) }
  let(:comment) { create(:comment, puzzle:) }

  def set_spoiler(user, spoiler: true, id: comment.id)
    execute_query(mutation, variables: { id:, spoiler: }, context: auth_context(user))
  end

  it "lets the commenter mark their own comment", :aggregate_failures do
    result = set_spoiler(comment.user)
    expect(gql_data(result, "setCommentSpoiler", "errors")).to be_empty
    expect(comment.reload).to be_spoiler
    expect(comment.spoiler_marked_by).to eq(comment.user)
    expect(gql_data(result, "setCommentSpoiler", "comment", "spoilerMarkedBySetter")).to be(false)
  end

  it "lets the commenter unmark a flag they applied themselves" do
    comment.update!(spoiler: true, spoiler_marked_by: comment.user)
    set_spoiler(comment.user, spoiler: false)
    expect(comment.reload).not_to be_spoiler
  end

  it "lets the puzzle author mark someone else's comment with attribution", :aggregate_failures do
    result = set_spoiler(puzzle.author)
    expect(comment.reload.spoiler_marked_by).to eq(puzzle.author)
    expect(gql_data(result, "setCommentSpoiler", "comment", "spoilerMarkedBySetter")).to be(true)
  end

  it "stops the commenter from stripping the author's moderation flag", :aggregate_failures do
    comment.update!(spoiler: true, spoiler_marked_by: puzzle.author)
    result = set_spoiler(comment.user, spoiler: false)
    expect(gql_data(result, "setCommentSpoiler", "errors")).to include(a_string_matching(/unmark/))
    expect(comment.reload).to be_spoiler
  end

  it "lets the puzzle author unmark a commenter's self-applied flag" do
    comment.update!(spoiler: true, spoiler_marked_by: comment.user)
    set_spoiler(puzzle.author, spoiler: false)
    expect(comment.reload).not_to be_spoiler
  end

  it "lets an admin unmark anything" do
    comment.update!(spoiler: true, spoiler_marked_by: puzzle.author)
    set_spoiler(create(:user, role: :admin), spoiler: false)
    expect(comment.reload).not_to be_spoiler
  end

  it "hides the comment from unrelated users" do
    result = set_spoiler(create(:user))
    expect(gql_errors(result).first["message"]).to eq("Comment not found")
  end

  it "requires authentication" do
    result = execute_query(mutation, variables: { id: comment.id, spoiler: true })
    expect(gql_errors(result)).not_to be_empty
  end
end
