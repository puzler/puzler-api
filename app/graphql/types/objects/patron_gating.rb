module Types
  module Objects
    # Shared teaser-mode plumbing for PuzzleType and CollectionType. Since the
    # single-record resolvers return patrons_only records in "teaser mode" for
    # non-qualifying viewers, the types themselves must withhold content fields
    # whenever `teaser_locked?` — meta fields (title, author, ratings, the gate
    # itself) stay, content never leaves the server.
    module PatronGating
      def patron_gate
        object.patron_gate if object.visible_patrons_only?
      end

      # Everything the teaser lock panel needs, resolved per-viewer. Null for
      # non-patron visibilities.
      def patron_access
        return nil unless object.visible_patrons_only?

        gate = object.patron_gate
        min_tier = gate&.min_tier if gate&.mode_min_tier?
        campaign = object.author&.patreon_campaign
        {
          has_access: viewer_can_open?,
          locked_reason: viewer_can_open? ? nil : patron_checker.locked_reason(object),
          required_tier_title: min_tier&.title,
          required_amount_cents: gate&.mode_min_amount? ? gate.min_amount_cents : min_tier&.amount_cents,
          campaign_title: campaign&.title,
          campaign_url: campaign&.url
        }
      end

      def released_at
        object.released_at if author_or_admin?
      end

      def is_released
        object.released?
      end

      private

      def patron_checker
        context[:patron_access] ||= PatronAccess.new(context[:current_user])
      end

      def viewer_can_open?
        return @viewer_can_open if defined?(@viewer_can_open)

        @viewer_can_open = object.viewable_by?(
          context[:current_user],
          share_token: context[:share_token],
          patron_access: patron_checker
        )
      end

      # Content fields are withheld exactly for the case the resolvers newly
      # let through: a patrons_only record the viewer doesn't qualify for.
      # Every other visibility keeps today's resolver-level gating.
      def teaser_locked?
        object.visible_patrons_only? && !viewer_can_open?
      end
    end
  end
end
