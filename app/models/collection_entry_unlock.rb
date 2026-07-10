# Records that an actor opened a codeword gate on one collection entry. A row
# belongs to a user OR carries an opaque guest token (see Actor#owner_attrs);
# unlocks are permanent per actor, like solve history.
class CollectionEntryUnlock < ApplicationRecord
  belongs_to :collection_entry
  belongs_to :user, optional: true

  validates :guest_token, presence: true, unless: -> { user_id.present? }

  scope :for_actor, ->(actor) {
    actor.user? ? where(user_id: actor.user_id) : where(guest_token: actor.guest_token)
  }
end
