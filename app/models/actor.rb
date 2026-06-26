# Who is acting on a play session: a logged-in User (user_id) or a guest — an
# opaque, client-generated token kept in the browser's localStorage. Collaboration
# tables store one or the other; access is always gated by PuzzlePlay#accessible_by?,
# so a self-asserted guest token reaches nothing until it owns or joins a play.
# Not an ActiveRecord model — a plain value object that normalizes "who is acting"
# so callers don't branch on user-vs-guest everywhere.
class Actor
  attr_reader :user, :guest_token

  def self.from_context(current_user:, guest_token:)
    return new(user: current_user) if current_user

    token = guest_token.presence
    token ? new(guest_token: token) : nil
  end

  def initialize(user: nil, guest_token: nil)
    @user = user
    @guest_token = guest_token
  end

  def user?
    !user.nil?
  end

  def guest?
    user.nil? && !guest_token.nil?
  end

  def user_id
    user&.id
  end

  # Stable, namespaced identity for presence rosters / colors / kick targeting.
  def key
    user? ? "user:#{user.id}" : "guest:#{guest_token}"
  end

  # Columns to write when this actor owns or joins a row.
  def owner_attrs
    user? ? { user: user } : { guest_token: guest_token }
  end
  alias participant_attrs owner_attrs

  def token_created_by_attrs
    user? ? { created_by: user } : { created_by_guest_token: guest_token }
  end
end
