class Comment < ApplicationRecord
  # Discord-style section-spoiler delimiter: ||hidden text|| inside the body.
  SPOILER_DELIMITER = "||".freeze

  belongs_to :puzzle
  belongs_to :user
  belongs_to :parent, class_name: "Comment", optional: true
  # Who flagged the whole comment as a spoiler: the commenter themselves, or the
  # puzzle's author / an admin moderating someone else's comment.
  belongs_to :spoiler_marked_by, class_name: "User", optional: true

  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent

  validates :body, presence: true, length: { maximum: 2000 }
  validates :spoiler_marked_by, presence: true, if: :spoiler?

  scope :top_level, -> { where(parent_id: nil) }
  scope :by_newest, -> { order(created_at: :desc) }

  # Split the body into [[:text, s], [:spoiler, s]] runs. Parts alternate
  # text/spoiler; an unbalanced trailing `||` leaves the final part as literal
  # text (never silently hidden), and empty spoiler runs collapse to nothing.
  def segments
    return [ [ :spoiler, body ] ] if spoiler?

    parts = body.split(SPOILER_DELIMITER, -1)
    # Even part count means an odd number of delimiters: the last part was
    # never closed, so glue it back onto the preceding text as literal `||`.
    unclosed = parts.length.even? ? parts.pop : nil

    out = []
    parts.each_with_index do |part, index|
      kind = index.odd? ? :spoiler : :text
      out << [ kind, part ] unless part.empty?
    end
    out << [ :text, "#{SPOILER_DELIMITER}#{unclosed}" ] if unclosed
    out.empty? ? [ [ :text, body ] ] : out
  end

  def section_spoilers?
    !spoiler? && body.scan(SPOILER_DELIMITER).length >= 2
  end

  def spoilers?
    spoiler? || section_spoilers?
  end

  # Who may read spoiler content: the commenter, the puzzle's author, admins,
  # and anyone (guests included) who has solved the puzzle.
  def spoilers_visible_to?(user, actor: nil)
    return true if user && (user.id == user_id || user.admin?)
    return true if user && puzzle.author_id == user.id

    puzzle.solved_by?(actor || (user && Actor.new(user:)))
  end
end
