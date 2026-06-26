module ApplicationCable
  class Channel < ActionCable::Channel::Base
    # The acting identity (user or guest) for this connection. current_user and
    # guest_token are connection identifiers exposed to channels by identified_by.
    def current_actor
      Actor.from_context(current_user: current_user, guest_token: guest_token)
    end
  end
end
