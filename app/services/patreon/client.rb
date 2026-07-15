require "net/http"
require "json"

module Patreon
  # Thin HTTP client for the Patreon API v2. Returns parsed JSON:API hashes;
  # interpreting them is the sync services' job. Every call passes explicit
  # fields[...] params because v2 returns NO attributes by default.
  class Client
    class Error < StandardError; end
    class Unauthorized < Error; end # 401 — Token.with_retry refreshes and retries once
    class RateLimited < Error; end  # 429 — callers/jobs retry with backoff
    class NotFound < Error; end     # 404 — campaign/webhook gone on Patreon's side

    BASE = "https://www.patreon.com/api/oauth2/v2".freeze
    TIMEOUT = 10 # seconds — third party; don't hang a request on it

    MEMBER_FIELDS = %w[
      patron_status currently_entitled_amount_cents pledge_relationship_start
      last_charge_status
    ].join(",").freeze
    CAMPAIGN_FIELDS = %w[creation_name url currency patron_count].join(",").freeze
    TIER_FIELDS = %w[title amount_cents published].join(",").freeze

    def initialize(access_token)
      @access_token = access_token
    end

    # The token owner's memberships across every campaign they support, with
    # each membership's campaign and entitled tiers included.
    def identity_with_memberships
      get("/identity", {
        "include" => "memberships,memberships.campaign,memberships.currently_entitled_tiers",
        "fields[member]" => MEMBER_FIELDS,
        "fields[campaign]" => CAMPAIGN_FIELDS,
        "fields[tier]" => TIER_FIELDS
      })
    end

    # Campaigns OWNED by the token's user. Empty data = not a creator.
    def campaigns
      get("/campaigns", { "fields[campaign]" => CAMPAIGN_FIELDS })
    end

    def campaign_with_tiers(campaign_patreon_id)
      get("/campaigns/#{campaign_patreon_id}", {
        "include" => "tiers",
        "fields[campaign]" => CAMPAIGN_FIELDS,
        "fields[tier]" => TIER_FIELDS
      })
    end

    # One page of the campaign's member list (creator token required). Returns
    # [parsed_body, next_cursor]; next_cursor nil on the last page.
    def campaign_members(campaign_patreon_id, cursor: nil)
      params = {
        "include" => "currently_entitled_tiers,user",
        "fields[member]" => MEMBER_FIELDS,
        "fields[tier]" => TIER_FIELDS,
        "page[count]" => "500"
      }
      params["page[cursor]"] = cursor if cursor.present?

      body = get("/campaigns/#{campaign_patreon_id}/members", params)
      [ body, body.dig("meta", "pagination", "cursors", "next") ]
    end

    # Registers our per-campaign webhook. The returned secret signs every
    # delivery (HMAC-MD5 of the raw body) and is only revealed here.
    def create_webhook(campaign_patreon_id, uri:, triggers:)
      post("/webhooks", {
        data: {
          type: "webhook",
          attributes: { triggers: triggers, uri: uri },
          relationships: {
            campaign: { data: { type: "campaign", id: campaign_patreon_id } }
          }
        }
      })
    end

    def update_webhook(webhook_patreon_id, paused:)
      patch("/webhooks/#{webhook_patreon_id}", {
        data: { type: "webhook", id: webhook_patreon_id, attributes: { paused: paused } }
      })
    end

    def delete_webhook(webhook_patreon_id)
      request(Net::HTTP::Delete.new(build_uri("/webhooks/#{webhook_patreon_id}")))
      true
    end

    private

    def get(path, params = {})
      parse(request(Net::HTTP::Get.new(build_uri(path, params))))
    end

    def post(path, payload)
      write(Net::HTTP::Post.new(build_uri(path)), payload)
    end

    def patch(path, payload)
      write(Net::HTTP::Patch.new(build_uri(path)), payload)
    end

    def write(req, payload)
      req["Content-Type"] = "application/json"
      req.body = JSON.generate(payload)
      parse(request(req))
    end

    def build_uri(path, params = {})
      uri = URI("#{BASE}#{path}")
      uri.query = URI.encode_www_form(params) if params.any?
      uri
    end

    def request(req)
      req["Authorization"] = "Bearer #{@access_token}"

      uri = req.uri
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = TIMEOUT
      http.read_timeout = TIMEOUT

      response = http.request(req)
      check!(response)
      response
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, IOError, SystemCallError => e
      raise Error, "Patreon request failed: #{e.message}"
    end

    def check!(response)
      case response.code.to_i
      when 200..299 then response
      when 401 then raise Unauthorized, "Patreon token rejected"
      when 404 then raise NotFound, "Patreon resource not found"
      when 429 then raise RateLimited, "Patreon rate limit hit"
      else raise Error, "Patreon returned #{response.code}"
      end
    end

    def parse(response)
      return {} if response.body.blank?

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise Error, "Patreon response unparseable: #{e.message}"
    end
  end
end
