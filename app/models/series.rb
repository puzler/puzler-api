class Series < ApplicationRecord
  self.table_name = "series"

  belongs_to :author, class_name: "User"

  has_many :series_entries, dependent: :destroy
  has_many :series_subscriptions, dependent: :destroy
  has_many :subscribers, through: :series_subscriptions, source: :user

  # Mirrors Collection's access model. "private"/"public" collide with Ruby
  # keywords, so visibility methods are prefixed (visible_public?, etc.).
  enum :visibility,
    { private: 0, unlisted: 1, public: 2, patrons_only: 3, subscribers_only: 4 },
    prefix: :visible

  before_create :generate_share_token

  validates :title, presence: true, length: { maximum: 100 }

  scope :publicly_visible, -> { visible_public }

  # Can this viewer open the series? Author/admin always; otherwise by
  # visibility. Private is author-only; the patron/subscriber tiers are stubbed.
  def viewable_by?(user, share_token: nil)
    return true if user && (user.id == author_id || user.admin?)

    case visibility
    when "public" then true
    when "unlisted" then share_token.present? && share_token == self.share_token
    else false
    end
  end

  private

  # Unguessable URL key for share links (mirrors Collection#generate_share_token).
  def generate_share_token
    self.share_token ||= SecureRandom.urlsafe_base64(16)
  end
end
