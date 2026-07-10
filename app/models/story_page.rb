# A narrative interlude an author can slot between puzzles in a collection
# (phase 2 of the rich-collections epic renders these; the model lands first so
# the polymorphic entry design is exercised end to end).
class StoryPage < ApplicationRecord
  belongs_to :author, class_name: "User"

  has_many :collection_entries, as: :entryable, dependent: :destroy

  include RichDescription
  rich_description_on :body_html

  validates :title, length: { maximum: 100 }
end
