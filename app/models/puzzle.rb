# frozen_string_literal: true

class Puzzle < ApplicationRecord
  belongs_to :user

  enum visibility: { private: 0, unlisted: 1, public: 2 }, _suffix: 'vis'

  validates :size, numericality: { greater_than_or_equal_to: 1 }
end
