class Folder < ApplicationRecord
  belongs_to :author, class_name: "User"
  # Self-association supports arbitrary nesting. Deleting a folder orphans its
  # children to the top level and unfiles its puzzles/collections rather than
  # cascading the delete (matches the "items are kept, just unfiled" UX).
  belongs_to :parent, class_name: "Folder", optional: true
  has_many :children, class_name: "Folder", foreign_key: :parent_id, dependent: :nullify, inverse_of: :parent
  has_many :puzzles, dependent: :nullify
  has_many :collections, dependent: :nullify

  validates :name, presence: true, length: { maximum: 100 }
  validate :parent_is_not_self_or_descendant

  # IDs of every folder beneath this one (any depth). Used both for cycle
  # prevention on reparenting and as a guard elsewhere; trees are shallow in
  # practice so the recursive walk is cheap.
  def descendant_ids
    ids = children.pluck(:id)
    ids + ids.flat_map { |child_id| Folder.find(child_id).descendant_ids }
  end

  private

  # A folder can't be its own ancestor: reject reparenting onto itself or any
  # of its descendants, which would create a cycle.
  def parent_is_not_self_or_descendant
    return if parent_id.blank?

    if parent_id == id
      errors.add(:parent_id, "can't be the folder itself")
    elsif persisted? && descendant_ids.include?(parent_id)
      errors.add(:parent_id, "can't be a descendant of the folder")
    end
  end
end
