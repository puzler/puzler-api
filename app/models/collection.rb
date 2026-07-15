class Collection < ApplicationRecord
  belongs_to :author, class_name: "User"
  belongs_to :folder, optional: true

  has_many :competition_runs, dependent: :destroy
  has_many :entries, class_name: "CollectionEntry", dependent: :destroy
  has_many :puzzle_entries, -> { where(entryable_type: "Puzzle") },
    class_name: "CollectionEntry"
  has_many :puzzles, through: :puzzle_entries, source: :entryable, source_type: "Puzzle"
  has_many :collection_solve_times, dependent: :destroy
  has_many :series_entries, as: :entryable, dependent: :destroy

  # Patron gating + lazy scheduled release (patron_gate, released/released?,
  # patron listing scopes).
  include PatronGateable

  # Mirrors Puzzle's access model. "private"/"public" collide with Ruby keywords,
  # so visibility methods are prefixed (visible_public?, etc.). `mode` governs
  # ordering only — timing/competition is a separate setting added later.
  # `containers_only` (added 2026-06-14) is hidden from the archive but surfaced
  # inside the author's own series; for direct access it behaves like `unlisted`.
  enum :visibility,
    { private: 0, unlisted: 1, public: 2, patrons_only: 3, subscribers_only: 4,
      containers_only: 5 },
    prefix: :visible
  enum :mode, { unordered: 0, sequence: 1 }

  # What this collection IS: a plain list, a rich hunt (covers/story/gates), or
  # a server-refereed competition. Kind gates which features render; flipping
  # kind never destroys dormant data (a hunt's story pages survive a switch to
  # basic and return when switched back).
  enum :kind, { basic: 0, hunt: 1, competition: 2 }, prefix: :kind
  # How competition submissions behave for solvers: blind (no verdict, resubmit
  # freely, last one counts), instant (verdict shown, each wrong costs the
  # penalty), single (one submission per puzzle).
  enum :submission_policy, { blind: 0, instant: 1, single: 2 }, prefix: :policy

  include ShareTokenable

  # Rich page body (TipTap HTML, sanitized) + embedded images, like a puzzle's
  # description page.
  include RichDescription

  # Standardized cover crops: the page hero keeps the upload's aspect (bounded),
  # archive/profile cards get a 16:9 fill, and the og crop matches the size
  # social cards expect.
  COVER_HERO_VARIANT = { resize_to_limit: [ 1600, 900 ] }.freeze
  COVER_CARD_VARIANT = { resize_to_fill: [ 640, 360 ] }.freeze
  COVER_OG_VARIANT = { resize_to_fill: [ 1200, 630 ] }.freeze

  has_one_attached :cover_image do |attachable|
    attachable.variant :hero, **COVER_HERO_VARIANT
    attachable.variant :card, **COVER_CARD_VARIANT
    attachable.variant :og, **COVER_OG_VARIANT
  end

  # Curated page accents (closed sets; 0 = default Ink & Paper). The values map
  # to CSS classes in the app (see app/src/style.css "Collection accents").
  enum :accent_color, { default: 0, forest: 1, wine: 2, ocean: 3, ember: 4, violet: 5 },
    prefix: :accent
  enum :bg_treatment, { default: 0, parchment: 1, linen: 2, dusk: 3 }, prefix: :bg
  enum :title_font, { default: 0, serif: 1, mono: 2 }, prefix: :font

  validates :title, presence: true, length: { maximum: 100 }
  validates :time_limit_seconds, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :penalty_points, :bonus_points_per_minute,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Once anyone has started a run the contest terms are frozen: kind and
  # competition config edits are rejected (late entrants face the same rules).
  def competition_locked?
    kind_competition? && competition_runs.exists?
  end

  scope :publicly_visible, -> { visible_public.released }

  # Anchors the back-catalog gate and orders patron feeds (see PatronGateable).
  # Collections have no published_at; creation is the closest release moment.
  def self.patron_release_fallback_column
    :created_at
  end
  scope :by_rating, -> { order(avg_rating: :desc) }
  scope :by_popularity, -> { order(solve_count: :desc) }

  # Refresh the denormalized rating/solve aggregates from member puzzles:
  # average of members' star ratings and the sum of their solve counts. Also
  # cascades to any series this collection belongs to, since their aggregates
  # roll up these same puzzles.
  def recompute_aggregates!
    update_columns(
      avg_rating: puzzles.where.not(avg_rating: nil).average(:avg_rating)&.round(2),
      solve_count: puzzles.sum(:solve_count)
    )
    containing_series.each(&:recompute_aggregates!)
  end

  # Hosted URLs for the normalized cover crops; nil when no cover is set.
  def cover_image_url
    cover_variant_url(:hero)
  end

  def cover_thumb_url
    cover_variant_url(:card)
  end

  def og_image_url
    cover_variant_url(:og)
  end

  # Series that include this collection as an entry.
  def containing_series
    Series.joins(:series_entries)
          .where(series_entries: { entryable_type: "Collection", entryable_id: id })
          .distinct
  end

  def effective_release_at
    released_at || created_at
  end

  # Can this viewer open the collection? Author/admin always; otherwise by
  # visibility. Private is author-only (no per-user grants for collections);
  # patrons_only checks cached Patreon entitlement, and a share_token does NOT
  # bypass it. The subscriber tier stays stubbed.
  def viewable_by?(user, share_token: nil, patron_access: nil)
    return true if user && (user.id == author_id || user.admin?)
    return false unless released?

    case visibility
    when "public" then true
    when "unlisted", "containers_only" then share_token.present? && share_token == self.share_token
    when "patrons_only"
      user.present? && (patron_access || PatronAccess.new(user)).satisfies?(self)
    else false
    end
  end

  private

  def cover_variant_url(name)
    return nil unless cover_image.attached?

    Rails.application.routes.url_helpers.rails_representation_url(
      cover_image.variant(name), host: ENV.fetch("API_URL", "http://localhost:3000")
    )
  end
end
