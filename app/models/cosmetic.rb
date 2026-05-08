class Cosmetic < ApplicationRecord
  belongs_to :puzzle

  enum :cosmetic_type, { line: 0, cell_color: 1, shape: 2, text: 3 }

  validates :position, presence: true
  validates :style, presence: true

  default_scope { order(:display_order) }
end
