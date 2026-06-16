require "rails_helper"

RSpec.describe "Folder mutations", type: :graphql do
  let(:user) { create(:user) }

  def gql(mutation, vars, ctx = nil)
    execute_query(mutation, variables: vars, context: ctx || auth_context(user))
  end

  describe "createFolder" do
    let(:mutation) { "mutation($name: String!, $parent: ID) { createFolder(input: { name: $name, parentId: $parent }) { folder { id name parentId puzzleCount } errors } }" }

    it "creates a folder", :aggregate_failures do
      data = gql_data(gql(mutation, { name: "Beginners" }), "createFolder")
      expect(data["errors"]).to be_empty
      expect(data["folder"]).to include("name" => "Beginners", "puzzleCount" => 0, "parentId" => nil)
    end

    it "nests under a parent folder when given a parentId" do
      parent = create(:folder, author: user)
      data = gql_data(gql(mutation, { name: "Child", parent: parent.id }), "createFolder")
      expect(data["folder"]["parentId"]).to eq(parent.id.to_s)
    end

    it "rejects a parent that isn't the user's" do
      message = gql_errors(gql(mutation, { name: "x", parent: create(:folder).id })).first["message"]
      expect(message).to eq("Parent folder not found")
    end

    it "requires authentication" do
      expect(gql_errors(gql(mutation, { name: "x" }, {})).first["message"]).to eq("Authentication required")
    end
  end

  describe "moveFolder" do
    let(:mutation) { "mutation($id: ID!, $parent: ID) { moveFolder(input: { id: $id, parentId: $parent }) { folder { id parentId } errors } }" }

    it "reparents a folder" do
      parent = create(:folder, author: user)
      child = create(:folder, author: user)
      gql(mutation, { id: child.id, parent: parent.id })
      expect(child.reload.parent_id).to eq(parent.id)
    end

    it "moves a folder to the top level with a null parent" do
      child = create(:folder, author: user, parent: create(:folder, author: user))
      gql(mutation, { id: child.id, parent: nil })
      expect(child.reload.parent_id).to be_nil
    end

    it "rejects a cycle", :aggregate_failures do
      parent = create(:folder, author: user)
      child = create(:folder, author: user, parent:)
      data = gql_data(gql(mutation, { id: parent.id, parent: child.id }), "moveFolder")
      expect(data["errors"]).not_to be_empty
      expect(parent.reload.parent_id).to be_nil
    end
  end

  describe "moveCollectionToFolder" do
    let(:mutation) { "mutation($c: ID!, $f: ID) { moveCollectionToFolder(input: { collectionId: $c, folderId: $f }) { collection { id } errors } }" }

    it "files a collection into a folder" do
      folder = create(:folder, author: user)
      collection = create(:collection, author: user)
      gql(mutation, { c: collection.id, f: folder.id })
      expect(collection.reload.folder_id).to eq(folder.id)
    end

    it "does not move another author's collection" do
      folder = create(:folder, author: user)
      message = gql_errors(gql(mutation, { c: create(:collection).id, f: folder.id })).first["message"]
      expect(message).to eq("Collection not found")
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
