class Folder < ApplicationRecord
  belongs_to :author, class_name: "User"
  # Self-association is wired now; flat-vs-nested folders is purely a UI concern.
  belongs_to :parent, class_name: "Folder", optional: true
  has_many :children, class_name: "Folder", foreign_key: :parent_id, dependent: :nullify, inverse_of: :parent
  has_many :puzzles, dependent: :nullify

  validates :name, presence: true, length: { maximum: 100 }
end
