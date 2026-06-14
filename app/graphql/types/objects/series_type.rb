module Types
  module Objects
    class SeriesType < BaseObject
      description "A subscribable, ordered container of puzzles and collections"

      field :author, UserType, null: false, description: "The setter who owns the series"
      field :description, String, null: true, description: "Optional description"
      field :entries, [ SeriesEntryType ], null: false,
        description: "Entries in order; non-authors see only the publicly-visible ones"
      field :entry_count, Integer, null: false, description: "Number of entries the viewer can see"
      field :id, ID, null: false, description: "Unique series ID"
      field :share_token, String, null: true,
        description: "Unguessable share key for unlisted access; only visible to the author"
      field :subscribed, Boolean, null: false,
        description: "Whether the current user is subscribed to this series"
      field :subscriber_count, Integer, null: false, description: "Number of subscribers"
      field :title, String, null: false, description: "Series title"
      field :visibility, Types::Enums::SeriesVisibilityEnum, null: false,
        description: "Access mode: private, unlisted, public, patrons_only, or subscribers_only"

      def entries
        visible_entries
      end

      def entry_count
        visible_entries.size
      end

      def subscriber_count
        object.series_subscriptions.count
      end

      def subscribed
        user = context[:current_user]
        return false unless user

        object.series_subscriptions.exists?(user_id: user.id)
      end

      def share_token
        object.share_token if author_or_admin?
      end

      private

      # Authors see every entry; everyone else sees only released entries whose
      # target may be shown inside a container, preserving series order.
      def visible_entries
        return object.series_entries.to_a if author_or_admin?

        object.series_entries.select { |entry| entry.released? && entry.viewable_in_container? }
      end

      def author_or_admin?
        context[:current_user]&.id == object.author_id || context[:current_user]&.admin?
      end
    end
  end
end
