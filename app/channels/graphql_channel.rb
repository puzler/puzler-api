# Executes GraphQL operations sent by the frontend's ActionCableLink. Queries and
# mutations get a single reply; subscriptions stream updates until the client
# unsubscribes. The connection is anonymous — per-subscription authorization is
# enforced inside each Subscriptions::* class via the tokens passed as arguments.
class GraphqlChannel < ApplicationCable::Channel
  def subscribed
    @subscription_ids = []
  end

  def unsubscribed
    @subscription_ids.each { |sid| ApiSchema.subscriptions.delete_subscription(sid) }
  end

  def execute(data)
    result = ApiSchema.execute(
      data["query"],
      context: { channel: self, current_user: current_user, guest_token: guest_token },
      variables: data["variables"] || {},
      operation_name: data["operationName"]
    )

    # A subscription's initial reply carries no payload — the root field is
    # skipped via `:no_response`, so it only registers the stream. graphql-ruby
    # still renders that as `{ "data" => {} }`, and forwarding it makes Apollo's
    # cache choke ("Missing field 'X' while writing result {}"). Only transmit
    # frames that actually carry data or errors; updates (and any query/mutation
    # replies) always do.
    payload = result.to_h
    transmit({ result: payload, more: result.subscription? }) if payload["data"].present? || payload["errors"].present?
    @subscription_ids << result.context[:subscription_id] if result.context[:subscription_id]
  end
end
