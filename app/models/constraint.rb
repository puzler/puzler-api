class Constraint < ApplicationRecord
  VALID_TYPES = %w[
    diagonal knights_move kings_move non_consecutive
    killer_cage irregular_region windoku clone
    thermometer arrow renban german_whispers dutch_whispers palindrome custom_line
  ].freeze

  belongs_to :puzzle

  validates :constraint_type, presence: true, inclusion: { in: VALID_TYPES, allow_blank: true }
  validates :data, presence: true

  default_scope { order(:display_order) }
end
