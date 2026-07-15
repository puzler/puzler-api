module Schemas
  # Shared single-record resolution for patron-gated puzzles/collections.
  # Instead of "nil unless viewable", gated records resolve in TEASER MODE for
  # non-qualifying viewers (the object types withhold content fields) so the
  # frontend can render the lock panel with a become-a-patron CTA — but only
  # when the creator left teasers on. Unreleased records stay nil (no
  # pre-announcement leak); so does everything non-patron that isn't viewable.
  module PatronTeaserResolution
    private

    def resolve_patron_gated(record, share_token: nil)
      return nil unless record

      # The types re-check access per field; hand them the token used here.
      context[:share_token] = share_token if share_token

      user = context[:current_user]
      checker = context[:patron_access] ||= PatronAccess.new(user)
      return record if record.viewable_by?(user, share_token:, patron_access: checker)

      return nil unless record.visible_patrons_only? && record.released?
      return nil if record.is_a?(Puzzle) && !record.published?

      campaign = record.author&.patreon_campaign
      return nil unless campaign&.teasers_enabled?

      # The viewer may have pledged moments ago: freshen their membership once
      # (throttled), then rebuild the request's checker so the type's own
      # access checks see the new rows. Resolves unlocked if the sync granted
      # access; teaser mode otherwise.
      # ::-prefixed: inside schema modules, a bare Patreon resolves to
      # Schemas::Patreon.
      if user && ::Patreon::EnsureFreshMembership.call(user, campaign)
        context[:patron_access] = PatronAccess.new(user)
      end
      record
    end
  end
end
