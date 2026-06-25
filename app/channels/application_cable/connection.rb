module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # Connections are anonymous — guests have no JWT and browsers can't set a
    # Bearer header on the WebSocket handshake. All authorization happens inside
    # the GraphQL subscriptions via the unguessable tokens passed as arguments.
  end
end
