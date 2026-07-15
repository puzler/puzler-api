# WebMock helpers for the Patreon API v2. Build JSON:API bodies inline so each
# spec states exactly the memberships/tiers it cares about.
module PatreonStubs
  API = "https://www.patreon.com/api/oauth2/v2".freeze
  TOKEN_ENDPOINT = "https://www.patreon.com/api/oauth2/token".freeze

  def stub_patreon_token_refresh(access_token: "new-access", refresh_token: "new-refresh",
                                 expires_in: 2_678_400, scope: nil, status: 200)
    body =
      if status == 200
        { access_token:, refresh_token:, expires_in:, scope: }.compact.to_json
      else
        { error: "invalid_grant" }.to_json
      end
    stub_request(:post, TOKEN_ENDPOINT).to_return(status:, body:, headers: json_headers)
  end

  # identity?include=memberships… — memberships is an array of hashes:
  # { campaign_id:, status:, amount_cents:, tier_ids:, pledge_start: }
  def stub_patreon_identity_memberships(memberships, status: 200)
    included = memberships.flat_map do |m|
      [ {
        type: "member",
        id: m[:member_id] || "member-#{m[:campaign_id]}",
        attributes: {
          patron_status: m.fetch(:status, "active_patron"),
          currently_entitled_amount_cents: m[:amount_cents] || 0,
          pledge_relationship_start: m[:pledge_start]&.iso8601,
          last_charge_status: m[:last_charge_status] || "Paid"
        },
        relationships: {
          campaign: { data: { type: "campaign", id: m[:campaign_id] } },
          currently_entitled_tiers: {
            data: (m[:tier_ids] || []).map { |id| { type: "tier", id: } }
          }
        }
      } ] + [ { type: "campaign", id: m[:campaign_id], attributes: {} } ]
    end

    body = {
      data: { type: "user", id: "patreon-user-1", attributes: {} },
      included: included
    }.to_json

    stub_request(:get, %r{#{Regexp.escape(API)}/identity})
      .to_return(status:, body:, headers: json_headers)
  end

  def stub_patreon_campaigns(campaigns, status: 200)
    body = {
      data: campaigns.map do |c|
        {
          type: "campaign", id: c[:id],
          attributes: {
            creation_name: c[:title] || "Campaign #{c[:id]}",
            url: c[:url] || "https://www.patreon.com/c#{c[:id]}",
            currency: c[:currency] || "USD",
            patron_count: c[:patron_count] || 0
          }
        }
      end
    }.to_json
    stub_request(:get, %r{#{Regexp.escape(API)}/campaigns(\?.*)?$})
      .to_return(status:, body:, headers: json_headers)
  end

  def stub_patreon_campaign_tiers(campaign_id, tiers, status: 200)
    body = {
      data: {
        type: "campaign", id: campaign_id, attributes: {},
        relationships: { tiers: { data: tiers.map { |t| { type: "tier", id: t[:id] } } } }
      },
      included: tiers.map do |t|
        { type: "tier", id: t[:id],
          attributes: { title: t[:title] || "Tier #{t[:id]}",
                        amount_cents: t[:amount_cents] || 100,
                        published: t.fetch(:published, true) } }
      end
    }.to_json
    stub_request(:get, %r{#{Regexp.escape(API)}/campaigns/#{campaign_id}\?})
      .to_return(status:, body:, headers: json_headers)
  end

  # members is an array of { member_id:, user_id:, status:, amount_cents:,
  # tier_ids:, pledge_start: }. Pass next_cursor to chain pages.
  def stub_patreon_campaign_members(campaign_id, members, next_cursor: nil, cursor: nil, status: 200)
    body = {
      data: members.map do |m|
        {
          type: "member", id: m[:member_id],
          attributes: {
            patron_status: m[:status] || "active_patron",
            currently_entitled_amount_cents: m[:amount_cents] || 0,
            pledge_relationship_start: m[:pledge_start]&.iso8601,
            last_charge_status: m[:last_charge_status] || "Paid"
          },
          relationships: {
            user: { data: { type: "user", id: m[:user_id] } },
            currently_entitled_tiers: {
              data: (m[:tier_ids] || []).map { |id| { type: "tier", id: } }
            }
          }
        }
      end,
      meta: { pagination: { cursors: { next: next_cursor } } }
    }.to_json

    stub = stub_request(:get, %r{#{Regexp.escape(API)}/campaigns/#{campaign_id}/members})
    stub = stub.with { |req| CGI.unescape(req.uri.query.to_s).include?("page[cursor]=#{cursor}") } if cursor
    stub.to_return(status:, body:, headers: json_headers)
  end

  def stub_patreon_webhook_create(webhook_id: "webhook-1", secret: "hook-secret", status: 201)
    body = { data: { type: "webhook", id: webhook_id, attributes: { secret: } } }.to_json
    stub_request(:post, "#{API}/webhooks").to_return(status:, body:, headers: json_headers)
  end

  def stub_patreon_webhook_update(webhook_id, status: 200)
    stub_request(:patch, "#{API}/webhooks/#{webhook_id}")
      .to_return(status:, body: { data: {} }.to_json, headers: json_headers)
  end

  def stub_patreon_webhook_delete(webhook_id, status: 204)
    stub_request(:delete, "#{API}/webhooks/#{webhook_id}").to_return(status:, body: "")
  end

  private

  def json_headers
    { "Content-Type" => "application/json" }
  end
end

RSpec.configure do |config|
  config.include PatreonStubs
end
