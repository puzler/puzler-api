# One ordered slot in a collection. The entryable is a Puzzle or a StoryPage;
# the entry row also carries the per-entry hunt gates (all opt-in): a codeword,
# hidden (invisible until its codeword is entered), and finale (unlocks when
# every other puzzle is solved). See CollectionGate for how they resolve.
class CollectionEntry < ApplicationRecord
  belongs_to :collection
  belongs_to :entryable, polymorphic: true

  has_many :unlocks, class_name: "CollectionEntryUnlock", dependent: :destroy

  default_scope { order(:position) }

  scope :puzzles, -> { where(entryable_type: "Puzzle") }

  validates :entryable_id, uniqueness: { scope: [ :collection_id, :entryable_type ] }
  # A hidden entry with no codeword could never be revealed.
  validates :codeword_digest, presence: { message: "is required for hidden entries" }, if: :hidden?

  # Codewords are a game mechanic, not credentials: normalized (case and
  # whitespace insensitive) and stored as a plain SHA-256 digest.
  def codeword=(word)
    self.codeword_digest = word.present? ? self.class.digest_codeword(word) : nil
  end

  def gated?
    codeword_digest.present?
  end

  def codeword_matches?(guess)
    gated? && codeword_digest == self.class.digest_codeword(guess)
  end

  def unlocked_by?(actor)
    return false unless actor

    unlocks.for_actor(actor).exists?
  end

  # Nil means released on creation; a future timestamp is a scheduled entry.
  def released?
    released_at.nil? || released_at <= Time.current
  end

  def self.digest_codeword(word)
    Digest::SHA256.hexdigest(word.to_s.strip.downcase)
  end
end
