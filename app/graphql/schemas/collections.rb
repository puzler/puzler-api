module Schemas
  module Collections
    module Queries
      include Types::Interfaces::BaseInterface
      description "Folder and collection queries"
      graphql_name "CollectionQueries"

      field :collection, Types::Objects::CollectionType, null: true,
        description: "Find a collection by ID, if the current user is allowed to see it" do
        argument :id, ID, required: true, description: "Collection ID to look up"
      end

      field :collection_by_token, Types::Objects::CollectionType, null: true,
        description: "Find a collection by its share token (for unlisted/series links)" do
        argument :token, String, required: true, description: "The collection's share token"
      end

      field :my_collections, [ Types::Objects::CollectionType ], null: false,
        description: "The current user's collections, newest first"

      field :my_folders, [ Types::Objects::FolderType ], null: false,
        description: "The current user's folders, in sort order"

      def collection(id:)
        record = Collection.find_by(id:)
        return nil unless record&.viewable_by?(context[:current_user])

        record
      end

      def collection_by_token(token:)
        record = Collection.find_by(share_token: token)
        return nil unless record&.viewable_by?(context[:current_user], share_token: token)

        record
      end

      def my_collections
        require_current_user!
        context[:current_user].collections.order(created_at: :desc)
      end

      def my_folders
        require_current_user!
        context[:current_user].folders.order(:position)
      end

      private

      def require_current_user!
        raise GraphQL::ExecutionError, "Authentication required" unless context[:current_user]
      end
    end

    module Mutations
      include Types::Interfaces::BaseInterface
      description "Mutations for managing folders and collections"
      graphql_name "CollectionMutations"

      field :add_puzzle_to_collection, mutation: ::Mutations::Collections::AddPuzzleToCollection,
        description: "Add a puzzle to a collection"
      field :create_collection, mutation: ::Mutations::Collections::CreateCollection,
        description: "Create a collection"
      field :create_folder, mutation: ::Mutations::Folders::CreateFolder,
        description: "Create a folder"
      field :delete_collection, mutation: ::Mutations::Collections::DeleteCollection,
        description: "Delete a collection"
      field :delete_folder, mutation: ::Mutations::Folders::DeleteFolder,
        description: "Delete a folder"
      field :move_puzzle_to_folder, mutation: ::Mutations::Folders::MovePuzzleToFolder,
        description: "File or unfile a puzzle"
      field :remove_puzzle_from_collection, mutation: ::Mutations::Collections::RemovePuzzleFromCollection,
        description: "Remove a puzzle from a collection"
      field :rename_folder, mutation: ::Mutations::Folders::RenameFolder,
        description: "Rename a folder"
      field :reorder_collection_puzzles, mutation: ::Mutations::Collections::ReorderCollectionPuzzles,
        description: "Reorder the puzzles in a collection"
      field :update_collection, mutation: ::Mutations::Collections::UpdateCollection,
        description: "Update a collection's metadata"
    end
  end
end
