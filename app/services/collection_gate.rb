# Resolves which of a collection's entries an actor can see and open. What
# applies depends on the collection's kind:
#   hunt        — the full gate stack: sequence mode, codewords, hidden bonus
#                 entries, finales, scheduled release.
#   basic       — sequence + scheduled release only; hunt gates lie dormant
#                 (their data survives kind switches untouched).
#   competition — everything locked until the viewer has a run (their timed
#                 attempt); open once a run exists, active or finished (review).
#                 Sequence and hunt gates are ignored; release is honored so
#                 authors can stage the pool. "Solved" maps to nothing here —
#                 competition submission state lives on the run, not plays.
# Authors always see everything. Solve state is per actor (user or guest
# token), so gating holds across devices for users and per browser for guests.
class CollectionGate
  # What the GraphQL layer renders: the entry plus its resolved state. Locked
  # story entries keep their title (teaser/TOC) but withhold the body upstream;
  # competition-locked entries withhold the puzzle too (no pre-run peeking).
  class GatedEntry
    attr_reader :entry, :locked, :solved

    delegate :id, :position, :entryable_type, :entryable, :gated?, :hidden?, :finale?, :released_at,
      :points, to: :entry

    def initialize(entry:, locked:, solved:)
      @entry = entry
      @locked = locked
      @solved = solved
    end
  end

  def initialize(collection, actor:, author_view: false, competition_run: nil)
    @collection = collection
    @actor = actor
    @author_view = author_view
    @competition_run = competition_run
  end

  # `entries` should already be filtered to what this viewer may know exists
  # (puzzle visibility). Unreleased entries are simply absent for non-authors,
  # so they never block a sequence or count toward a finale.
  def call(entries)
    return competition_call(entries) if @collection.kind_competition?

    hunt = @collection.kind_hunt?
    unlocked_ids = hunt ? unlocked_entry_ids(entries) : Set.new
    solved_ids = solved_puzzle_ids(entries)

    # Basic is strictly puzzles: dormant story pages stay author-only.
    visible = entries.select do |e|
      next true if @author_view

      (hunt || e.entryable_type == "Puzzle") &&
        e.released? && (!hunt || !e.hidden? || unlocked_ids.include?(e.id))
    end

    required = visible.select { |e| !e.finale? && e.entryable_type == "Puzzle" }
    finale_ready = required.any? && required.all? { |e| solved_ids.include?(e.entryable_id) }

    blocked = false
    visible.map do |entry|
      gate_open = !hunt || !entry.gated? || unlocked_ids.include?(entry.id)
      finale_open = !hunt || !entry.finale? || finale_ready
      locked = !@author_view && (blocked || !gate_open || !finale_open)

      solved = entry.entryable_type == "Puzzle" && solved_ids.include?(entry.entryable_id)
      # In sequence mode any unsolved puzzle, locked or not, seals what follows.
      blocked = true if sequence? && !@author_view && entry.entryable_type == "Puzzle" && !solved

      GatedEntry.new(entry:, locked:, solved:)
    end
  end

  private

  # Competition: released puzzle entries only (strictly puzzles, like basic);
  # locked as a block until the viewer has a run. Solved is intentionally never
  # surfaced from plays (a blind contest must not reflect board state through
  # checkmarks).
  def competition_call(entries)
    visible = entries.select do |e|
      @author_view || (e.released? && e.entryable_type == "Puzzle")
    end
    locked = !@author_view && @competition_run.nil?
    visible.map { |entry| GatedEntry.new(entry:, locked:, solved: false) }
  end

  def sequence?
    @collection.sequence?
  end

  def unlocked_entry_ids(entries)
    return Set.new unless @actor

    CollectionEntryUnlock.where(collection_entry_id: entries.map(&:id))
                         .for_actor(@actor).pluck(:collection_entry_id).to_set
  end

  def solved_puzzle_ids(entries)
    return Set.new unless @actor

    ids = entries.select { |e| e.entryable_type == "Puzzle" }.map(&:entryable_id)
    PuzzlePlay.where(puzzle_id: ids, is_solved: true)
              .where(**@actor.owner_attrs).pluck(:puzzle_id).to_set
  end
end
