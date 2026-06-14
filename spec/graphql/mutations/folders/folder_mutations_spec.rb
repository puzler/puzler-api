require "rails_helper"

RSpec.describe "Folder mutations", type: :graphql do
  let(:user) { create(:user) }

  def gql(mutation, vars, ctx = nil)
    execute_query(mutation, variables: vars, context: ctx || auth_context(user))
  end

  describe "createFolder" do
    let(:mutation) { "mutation($name: String!) { createFolder(input: { name: $name }) { folder { id name puzzleCount } errors } }" }

    it "creates a folder", :aggregate_failures do
      data = gql_data(gql(mutation, { name: "Beginners" }), "createFolder")
      expect(data["errors"]).to be_empty
      expect(data["folder"]).to include("name" => "Beginners", "puzzleCount" => 0)
    end

    it "requires authentication" do
      expect(gql_errors(gql(mutation, { name: "x" }, {})).first["message"]).to eq("Authentication required")
    end
  end

  describe "movePuzzleToFolder" do
    let(:mutation) { "mutation($p: ID!, $f: ID) { movePuzzleToFolder(input: { puzzleId: $p, folderId: $f }) { puzzle { id } errors } }" }

    it "files a puzzle into a folder" do
      folder = create(:folder, author: user)
      puzzle = create(:puzzle, author: user)
      gql(mutation, { p: puzzle.id, f: folder.id })
      expect(puzzle.reload.folder_id).to eq(folder.id)
    end

    it "unfiles a puzzle when folderId is null" do
      puzzle = create(:puzzle, author: user, folder: create(:folder, author: user))
      gql(mutation, { p: puzzle.id, f: nil })
      expect(puzzle.reload.folder_id).to be_nil
    end

    it "does not move another author's puzzle" do
      folder = create(:folder, author: user)
      message = gql_errors(gql(mutation, { p: create(:puzzle).id, f: folder.id })).first["message"]
      expect(message).to eq("Puzzle not found")
    end
  end

  describe "deleteFolder" do
    let(:mutation) { "mutation($id: ID!) { deleteFolder(input: { id: $id }) { success errors } }" }

    it "deletes the folder and unfiles its puzzles", :aggregate_failures do
      folder = create(:folder, author: user)
      puzzle = create(:puzzle, author: user, folder:)
      expect(gql_data(gql(mutation, { id: folder.id }), "deleteFolder", "success")).to be(true)
      expect(puzzle.reload.folder_id).to be_nil
    end
  end
end
