# Resolves which of a collection's entries an actor can see and open, folding
# together every opt-in hunt gate: sequence mode (unsolved puzzle locks what
# follows), codeword gates, hidden bonus entries (absent until their codeword
# is entered), and finale entries (locked until every other puzzle is solved).
# A collection with no gates set resolves to fully open, and authors always see
# everything. Solve state is per actor (user or guest token), so gating holds
# across devices for users and per browser for guests.
class CollectionGate
  # What the GraphQL layer renders: the entry plus its resolved state. Locked
  # story entries keep their title (teaser/TOC) but withhold the body upstream.
  class GatedEntry
    attr_reader :entry, :locked, :solved

    delegate :id, :position, :entryable_type, :entryable, :gated?, :hidden?, :finale?, :released_at,
      to: :entry

    def initialize(entry:, locked:, solved:)
      @entry = entry
      @locked = locked
      @solved = solved
    end
  end

  def initialize(collection, actor:, author_view: false)
    @collection = collection
    @actor = actor
    @author_view = author_view
  end

  # `entries` should already be filtered to what this viewer may know exists
  # (puzzle visibility); release, hidden-entry, and lock resolution happens
  # here. Unreleased entries are simply absent for non-authors, so they never
  # block a sequence or count toward a finale until their moment arrives.
  def call(entries)
    unlocked_ids = unlocked_entry_ids(entries)
    solved_ids = solved_puzzle_ids(entries)

    visible = entries.select do |e|
      @author_view || (e.released? && (!e.hidden? || unlocked_ids.include?(e.id)))
    end

    required = visible.select { |e| !e.finale? && e.entryable_type == "Puzzle" }
    finale_ready = required.any? && required.all? { |e| solved_ids.include?(e.entryable_id) }

    blocked = false
    visible.map do |entry|
      gate_open = !entry.gated? || unlocked_ids.include?(entry.id)
      finale_open = !entry.finale? || finale_ready
      locked = !@author_view && (blocked || !gate_open || !finale_open)

      solved = entry.entryable_type == "Puzzle" && solved_ids.include?(entry.entryable_id)
      # In sequence mode any unsolved puzzle, locked or not, seals what follows.
      blocked = true if sequence? && !@author_view && entry.entryable_type == "Puzzle" && !solved

      GatedEntry.new(entry:, locked:, solved:)
    end
  end

  private

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
