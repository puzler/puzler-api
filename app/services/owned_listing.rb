# Shared search / filter / sort / paginate logic for listings of owned records
# (My Puzzles, My Collections, My Series) and the public puzzle archive. Keeping
# one implementation means the lists — and any future ones — stay consistent and
# only have to be tuned in a single place. Archive-only facets (time range,
# setter tier, difficulty, tags, rating, featured, grid size, my-status) stay
# nil for the My-* lists and short-circuit.
#
# `filter` returns a relation (composable); `apply` wraps it with offset
# pagination and returns a Page struct the connection types render.
class OwnedListing
  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 100

  # Result of a paginated query. total_count is computed on the filtered scope
  # before limiting, so the client can render page controls.
  Page = Struct.new(:nodes, :total_count, :page, :per_page, keyword_init: true) do
    def total_pages = per_page.positive? ? (total_count.to_f / per_page).ceil : 0
    def has_next_page = page < total_pages
    def has_previous_page = page > 1
  end

  class << self
    def apply(scope, page: 1, per_page: DEFAULT_PER_PAGE, **filters)
      scope = filter(scope, **filters)
      paginate(scope, page:, per_page:)
    end

    # Apply the shared filters/sort to a scope, returning a relation. Pass
    # `constraints: true` for entities with a constraint_types array column
    # (puzzles), `folders: true` for entities filed in folders, and
    # `draft_bucket: true` for entities with a draft status that DRAFT filters.
    # `viewer` powers the my_status facet; archive facets only apply to puzzles.
    def filter(scope, search: nil, constraint_types: nil, match_mode: "ANY",
               visibilities: nil, folder_id: nil, sort: "RECENT",
               author_username: nil, time_range: nil, setter_tier: nil,
               difficulties: nil, tags: nil, min_rating: nil, my_status: nil,
               featured: nil, grid_sizes: nil, viewer: nil,
               constraints: false, folders: false, draft_bucket: false, recent_by: :created_at)
      # Join the author table once if any author-based filter needs it.
      if [ search, author_username, setter_tier ].any?(&:present?)
        scope = scope.left_outer_joins(:author)
      end

      scope = apply_search(scope, search)
      scope = apply_author(scope, author_username)
      scope = apply_setter_tier(scope, setter_tier)
      scope = apply_constraints(scope, constraint_types, match_mode) if constraints
      scope = apply_visibility(scope, visibilities, draft_bucket)
      scope = apply_folder(scope, folder_id) if folders
      scope = apply_time_range(scope, time_range, recent_by)
      scope = apply_difficulties(scope, difficulties)
      scope = apply_tags(scope, tags)
      scope = apply_min_rating(scope, min_rating)
      scope = apply_featured(scope, featured)
      scope = apply_grid_sizes(scope, grid_sizes)
      scope = apply_my_status(scope, my_status, viewer)
      apply_sort(scope, sort, recent_by)
    end

    def paginate(scope, page: 1, per_page: DEFAULT_PER_PAGE)
      page = [ page.to_i, 1 ].max
      per_page = per_page.to_i.clamp(1, MAX_PER_PAGE)
      total = scope.except(:order, :includes).count
      nodes = scope.offset((page - 1) * per_page).limit(per_page).to_a
      Page.new(nodes:, total_count: total, page:, per_page:)
    end

    private

    # The author table is joined by `filter` before this runs.
    def apply_search(scope, search)
      return scope if search.blank?

      term = "%#{ActiveRecord::Base.sanitize_sql_like(search.strip)}%"
      scope.where(
        "#{scope.table_name}.title ILIKE :q OR #{scope.table_name}.description ILIKE :q " \
        "OR users.username ILIKE :q OR users.display_name ILIKE :q",
        q: term
      )
    end

    def apply_author(scope, author_username)
      author_username.present? ? scope.where(users: { username: author_username }) : scope
    end

    def apply_setter_tier(scope, setter_tier)
      return scope if setter_tier.blank?

      tier = User.setter_tiers[setter_tier.downcase]
      tier ? scope.where(users: { setter_tier: tier }) : scope
    end

    # ANY: the record uses at least one of the listed constraint types (array
    # overlap). ALL: it uses every listed type (array contains).
    def apply_constraints(scope, constraint_types, match_mode)
      return scope if constraint_types.blank?

      operator = match_mode == "ALL" ? "@>" : "&&"
      scope.where(
        "#{scope.table_name}.constraint_types #{operator} ARRAY[?]::varchar[]",
        constraint_types
      )
    end

    # Filter to any of the requested visibility buckets (ANY semantics). Wire
    # values arrive UPPERCASE (e.g. "PUBLIC") and are downcased to enum keys.
    # When draft_bucket is set, "DRAFT" matches by status and a record's bucket
    # is DRAFT while unpublished (mirroring the list's "Draft" label), so a
    # visibility value only matches published records.
    def apply_visibility(scope, visibilities, draft_bucket)
      return scope if visibilities.blank?

      wants_draft = draft_bucket && visibilities.any? { |v| v.casecmp?("DRAFT") }
      vis = visibilities.reject { |v| v.casecmp?("DRAFT") }.map(&:downcase)

      return (vis.any? ? scope.where(visibility: vis) : scope) unless draft_bucket

      table = scope.table_name
      clauses = []
      params = []
      if wants_draft
        clauses << "#{table}.status = ?"
        params << scope.klass.statuses[:draft]
      end
      if vis.any?
        clauses << "(#{table}.status = ? AND #{table}.visibility IN (?))"
        params << scope.klass.statuses[:published]
        params << vis.map { |v| scope.klass.visibilities[v] }
      end
      clauses.empty? ? scope : scope.where(clauses.join(" OR "), *params)
    end

    # folder_id: "all" (or blank) = no filter, "unfiled" = top-level only,
    # otherwise a specific folder.
    def apply_folder(scope, folder_id)
      case folder_id
      when nil, "", "all" then scope
      when "unfiled" then scope.where(folder_id: nil)
      else scope.where(folder_id:)
      end
    end

    # Window on the recency column (published_at for the archive). Built via
    # Arel so the column identifier is never string-interpolated into SQL.
    def apply_time_range(scope, time_range, recent_by)
      return scope if time_range.blank? || time_range == "ALL_TIME"

      ago = { "THIS_WEEK" => 1.week.ago, "THIS_MONTH" => 1.month.ago, "THIS_YEAR" => 1.year.ago }[time_range]
      ago ? scope.where(scope.klass.arel_table[recent_by].gteq(ago)) : scope
    end

    # Match puzzles whose effective difficulty rounds to one of the levels.
    # Nulls (no author value and < cutoff votes) round to null and are excluded.
    def apply_difficulties(scope, difficulties)
      return scope if difficulties.blank?

      scope.where("ROUND(#{scope.table_name}.effective_difficulty) IN (?)", difficulties)
    end

    # Any-match on tag slugs, via a subquery so pagination counts stay correct.
    def apply_tags(scope, tags)
      return scope if tags.blank?

      scope.where(id: scope.klass.unscoped.joins(:tags).where(tags: { slug: tags }).select(:id))
    end

    def apply_min_rating(scope, min_rating)
      min_rating.present? ? scope.where("#{scope.table_name}.avg_rating >= ?", min_rating) : scope
    end

    def apply_featured(scope, featured)
      featured ? scope.where(featured: true) : scope
    end

    # grid_sizes: array of "ROWSxCOLS" strings, OR-combined.
    def apply_grid_sizes(scope, grid_sizes)
      return scope if grid_sizes.blank?

      pairs = grid_sizes.filter_map do |size|
        rows, cols = size.to_s.split("x", 2)
        [ rows.to_i, cols.to_i ] if rows.present? && cols.present?
      end
      return scope if pairs.empty?

      table = scope.table_name
      clause = pairs.map { "(#{table}.grid_rows = ? AND #{table}.grid_cols = ?)" }.join(" OR ")
      scope.where(clause, *pairs.flatten)
    end

    # Filter by the viewer's relationship to the puzzle. Anonymous viewers can't
    # have a status, so it no-ops (degrades to unfiltered). Subqueries keep
    # pagination counts accurate.
    def apply_my_status(scope, my_status, viewer)
      return scope if my_status.blank? || viewer.nil?

      solved = PuzzlePlay.completed.where(user_id: viewer.id).select(:puzzle_id)
      case my_status
      when "SOLVED" then scope.where(id: solved)
      when "UNSOLVED" then scope.where.not(id: solved)
      when "FAVORITED" then scope.where(id: Favorite.where(user_id: viewer.id).select(:puzzle_id))
      else scope
      end
    end

    def apply_sort(scope, sort, recent_by)
      case sort
      when "ALPHABETICAL" then scope.order(Arel.sql("LOWER(#{scope.table_name}.title) ASC"))
      when "RATING" then scope.by_rating
      when "SOLVES" then scope.by_popularity
      else scope.order(recent_by => :desc) # RECENT
      end
    end
  end
end
