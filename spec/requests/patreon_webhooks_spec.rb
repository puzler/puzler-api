require "rails_helper"

RSpec.describe "Patreon webhooks", type: :request do
  let(:campaign) { create(:patreon_campaign, webhook_secret: "hook-secret") }
  let(:patron) { create(:user) }

  before { create(:user_oauth_identity, :patreon, user: patron, uid: "p-user-1") }

  def member_payload(status: "active_patron", amount: 500, tier_ids: [ "t1" ], user_id: "p-user-1")
    {
      data: {
        type: "member", id: "member-1",
        attributes: {
          patron_status: status,
          currently_entitled_amount_cents: amount,
          pledge_relationship_start: 1.month.ago.iso8601
        },
        relationships: {
          user: { data: { type: "user", id: user_id } },
          currently_entitled_tiers: { data: tier_ids.map { |id| { type: "tier", id: } } }
        }
      }
    }.to_json
  end

  def post_webhook(body, event: "members:update", signature: nil)
    signature ||= OpenSSL::HMAC.hexdigest("MD5", "hook-secret", body)
    post "/webhooks/patreon/#{campaign.id}", params: body, headers: {
      "CONTENT_TYPE" => "application/json",
      "X-Patreon-Event" => event,
      "X-Patreon-Signature" => signature
    }
  end

  it "upserts a membership for a valid signed event", :aggregate_failures do
    post_webhook(member_payload)
    membership = patron.patreon_memberships.find_by(patreon_campaign: campaign)

    expect(response).to have_http_status(:ok)
    expect(membership).to be_patron_active_patron.and be_source_webhook
    expect(membership).to have_attributes(entitled_amount_cents: 500, entitled_patreon_tier_ids: [ "t1" ])
  end

  it "rejects a tampered body with 401 (the only deliberate non-2xx)", :aggregate_failures do
    body = member_payload
    signature = OpenSSL::HMAC.hexdigest("MD5", "hook-secret", body)
    post_webhook(body.sub("500", "9000"), signature: signature)

    expect(response).to have_http_status(:unauthorized)
    expect(patron.patreon_memberships.count).to eq(0)
  end

  it "rejects a missing signature" do
    post "/webhooks/patreon/#{campaign.id}", params: member_payload,
      headers: { "CONTENT_TYPE" => "application/json", "X-Patreon-Event" => "members:update" }
    expect(response).to have_http_status(:unauthorized)
  end

  it "200s and stores nothing for patrons who aren't Puzler users", :aggregate_failures do
    post_webhook(member_payload(user_id: "stranger"))
    expect(response).to have_http_status(:ok)
    expect(PatreonMembership.count).to eq(0)
  end

  it "demotes on members:delete but keeps join history", :aggregate_failures do
    membership = create(:patreon_membership, user: patron, patreon_campaign: campaign,
      first_active_at: 1.year.ago)

    post_webhook(member_payload, event: "members:delete")

    expect(membership.reload).to be_patron_former_patron
    expect(membership.first_active_at).to be_within(1.minute).of(1.year.ago)
  end

  it "updates entitlement on members:pledge:update" do
    create(:patreon_membership, user: patron, patreon_campaign: campaign, entitled_amount_cents: 300)

    post_webhook(member_payload(amount: 1000, tier_ids: [ "t2" ]), event: "members:pledge:update")

    expect(patron.patreon_memberships.first)
      .to have_attributes(entitled_amount_cents: 1000, entitled_patreon_tier_ids: [ "t2" ])
  end

  it "200s on unexpected payload shapes so Patreon never pauses the hook" do
    post_webhook({ data: "not a member object" }.to_json)
    expect(response).to have_http_status(:ok)
  end

  it "404s for unknown campaigns" do
    post "/webhooks/patreon/999999", params: member_payload,
      headers: { "CONTENT_TYPE" => "application/json" }
    expect(response).to have_http_status(:not_found)
  end
end
