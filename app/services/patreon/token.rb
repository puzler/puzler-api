require "net/http"
require "json"

module Patreon
  # Token lifecycle for stored Patreon OAuth identities. Patreon access tokens
  # expire (~31 days); this is the single chokepoint that refreshes them and
  # persists the rotated pair back onto the UserOauthIdentity.
  class Token
    class RefreshFailed < StandardError; end

    TOKEN_ENDPOINT = "https://www.patreon.com/api/oauth2/token".freeze
    # Refresh proactively when the token is this close to expiry (or when we
    # never recorded an expiry — identities linked before this feature).
    REFRESH_AHEAD = 2.days
    TIMEOUT = 10

    # A Client holding a currently-valid access token for this identity.
    def self.client_for(identity)
      refresh!(identity) if identity.expires_at.nil? || identity.expires_at < REFRESH_AHEAD.from_now
      Client.new(identity.access_token)
    end

    # Run a block against the identity's client; on a 401 (revoked or expired
    # early), force one refresh and retry. Any further auth failure means the
    # user must re-run OAuth — raised as RefreshFailed for callers to surface.
    def self.with_retry(identity)
      yield client_for(identity)
    rescue Client::Unauthorized
      refresh!(identity)
      begin
        yield Client.new(identity.access_token)
      rescue Client::Unauthorized
        raise RefreshFailed, "Patreon rejected a freshly refreshed token"
      end
    end

    # Exchange the stored refresh token for a new token pair and persist it.
    def self.refresh!(identity)
      raise RefreshFailed, "no refresh token stored" if identity.refresh_token.blank?

      body = post_refresh(identity.refresh_token)
      identity.update!(
        access_token: body.fetch("access_token"),
        refresh_token: body["refresh_token"].presence || identity.refresh_token,
        expires_at: Time.current + body.fetch("expires_in", 0).to_i.seconds,
        scopes: body["scope"].presence || identity.scopes
      )
    end

    def self.post_refresh(refresh_token)
      uri = URI(TOKEN_ENDPOINT)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = TIMEOUT
      http.read_timeout = TIMEOUT

      request = Net::HTTP::Post.new(uri)
      request.set_form_data(
        "grant_type" => "refresh_token",
        "refresh_token" => refresh_token,
        "client_id" => Rails.application.credentials.dig(:patreon, :client_id).to_s,
        "client_secret" => Rails.application.credentials.dig(:patreon, :client_secret).to_s
      )

      response = http.request(request)
      unless response.is_a?(Net::HTTPSuccess)
        raise RefreshFailed, "Patreon token refresh returned #{response.code}"
      end

      JSON.parse(response.body)
    rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, SocketError, IOError, SystemCallError => e
      raise RefreshFailed, "Patreon token refresh failed: #{e.message}"
    end
    private_class_method :post_refresh
  end
end
