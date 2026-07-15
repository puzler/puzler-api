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

      field :collections, Types::Objects::CollectionConnectionType, null: false, connection: false,
        description: "Browse the public collection archive with search/filter/sort/pagination" do
        argument :filter, Types::InputObjects::ListingFilterInput, required: false,
          description: "Search, filter, sort, and pagination options"
      end

      field :collection_leaderboard, [ Types::Objects::CollectionLeaderboardEntryType ], null: false,
        description: "Ranked solver times for a timed collection (solvers who completed every puzzle)" do
        argument :collection_id, ID, required: true, description: "The collection"
      end

      field :my_collections, Types::Objects::CollectionConnectionType, null: false, connection: false,
        description: "A page of the current user's collections, with search/filter/sort" do
        argument :filter, Types::InputObjects::ListingFilterInput, required: false,
          description: "Search, filter, sort, and pagination options"
      end

      field :my_folders, [ Types::Objects::FolderType ], null: false,
        description: "The current user's folders, flat, in sort order (for move-target lists)"

      field :my_folder_tree, [ Types::Objects::FolderType ], null: false,
        description: "The current user's top-level folders; nest via each folder's children"

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

      def collection_leaderboard(collection_id:)
        collection = Collection.find_by(id: collection_id)
        return [] unless collection&.viewable_by?(context[:current_user])

        puzzle_count = collection.puzzle_entries.count
        return [] if puzzle_count.zero?

        # Only solvers who have a time for every puzzle in the collection rank.
        totals = collection.collection_solve_times.group(:user_id)
                           .having("COUNT(*) = ?", puzzle_count).sum(:seconds)
        users = User.where(id: totals.keys).index_by(&:id)
        totals.sort_by { |_, secs| secs }.each_with_index.map do |(user_id, secs), index|
          user = users[user_id]
          { rank: index + 1, total_seconds: secs, username: user.username, display_name: user.display_name }
        end
      end

      def collections(filter: nil)
        scope = Collection.publicly_visible.includes(:author)
        args = filter ? filter.to_listing_args : {}
        OwnedListing.apply(scope, **args)
      end

      def my_collections(filter: nil)
        require_current_user!
        scope = context[:current_user].collections.includes(:author, :folder)
        args = filter ? filter.to_listing_args : {}
        OwnedListing.apply(scope, **args, folders: true)
      end

      def my_folders
        require_current_user!
        context[:current_user].folders.order(:position)
      end

      def my_folder_tree
        require_current_user!
        context[:current_user].folders.where(parent_id: nil).order(:position)
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
      field :add_story_page_to_collection, mutation: ::Mutations::Collections::AddStoryPageToCollection,
        description: "Create a story page at the end of a collection"
      field :create_collection, mutation: ::Mutations::Collections::CreateCollection,
        description: "Create a collection"
      field :create_folder, mutation: ::Mutations::Folders::CreateFolder,
        description: "Create a folder"
      field :delete_collection, mutation: ::Mutations::Collections::DeleteCollection,
        description: "Delete a collection"
      field :delete_folder, mutation: ::Mutations::Folders::DeleteFolder,
        description: "Delete a folder"
      field :move_collection_to_folder, mutation: ::Mutations::Folders::MoveCollectionToFolder,
        description: "File or unfile a collection"
      field :move_folder, mutation: ::Mutations::Folders::MoveFolder,
        description: "Reparent a folder"
      field :move_puzzle_to_folder, mutation: ::Mutations::Folders::MovePuzzleToFolder,
        description: "File or unfile a puzzle"
      field :record_collection_solve_time, mutation: ::Mutations::Collections::RecordCollectionSolveTime,
        description: "Record a solve time for a timed collection"
      field :remove_collection_cover_image, mutation: ::Mutations::Collections::RemoveCollectionCoverImage,
        description: "Remove a collection's cover image"
      field :remove_collection_entry, mutation: ::Mutations::Collections::RemoveCollectionEntry,
        description: "Remove an entry from a collection"
      field :rename_folder, mutation: ::Mutations::Folders::RenameFolder,
        description: "Rename a folder"
      field :reorder_collection_entries, mutation: ::Mutations::Collections::ReorderCollectionEntries,
        description: "Reorder all entries in a collection"
      field :submit_collection_codeword, mutation: ::Mutations::Collections::SubmitCollectionCodeword,
        description: "Try a codeword against a collection's gated entries"
      field :update_collection, mutation: ::Mutations::Collections::UpdateCollection,
        description: "Update a collection's metadata"
      field :update_collection_entry, mutation: ::Mutations::Collections::UpdateCollectionEntry,
        description: "Update an entry's hunt gates (codeword, hidden, finale)"
      field :update_collection_page_description, mutation: ::Mutations::Collections::UpdateCollectionPageDescription,
        description: "Save the rich page body for a collection"
      field :update_story_page, mutation: ::Mutations::Collections::UpdateStoryPage,
        description: "Update a story page's title or body"
      field :upload_collection_cover_image, mutation: ::Mutations::Collections::UploadCollectionCoverImage,
        description: "Upload or replace a collection's cover image"
      field :upload_collection_description_image, mutation: ::Mutations::Collections::UploadCollectionDescriptionImage,
        description: "Upload an image for a collection's rich page body"
      field :upload_story_page_image, mutation: ::Mutations::Collections::UploadStoryPageImage,
        description: "Upload an image for a story page's rich body"
    end
  end
end
