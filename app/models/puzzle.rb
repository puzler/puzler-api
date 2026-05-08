class Puzzle < ApplicationRecord
  belongs_to :author, class_name: "User"

  has_many :constraints, dependent: :destroy
  has_many :cosmetics, dependent: :destroy
  has_many :puzzle_plays, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :puzzle_tags, dependent: :destroy
  has_many :tags, through: :puzzle_tags

  enum :status, { draft: 0, published: 1, featured: 2 }
  enum :patron_visibility, { public_access: 0, patrons_only: 1 }, prefix: :patron

  validates :title, presence: true, length: { maximum: 100 }
  validates :grid_rows, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 25 }
  validates :grid_cols, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 25 }

  scope :published_or_featured, -> { where(status: [ :published, :featured ]) }
  scope :by_newest, -> { order(published_at: :desc) }
  scope :by_rating, -> { order(avg_rating: :desc) }
  scope :by_popularity, -> { order(solve_count: :desc) }
end
