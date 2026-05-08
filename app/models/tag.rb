class Tag < ApplicationRecord
  has_many :puzzle_tags, dependent: :destroy
  has_many :puzzles, through: :puzzle_tags

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 50 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }

  before_validation :generate_slug, if: -> { name.present? && slug.blank? }

  private

  def generate_slug
    self.slug = name.downcase.gsub(/\s+/, "-").gsub(/[^a-z0-9-]/, "")
  end
end
