require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Patreon < OmniAuth::Strategies::OAuth2
      option :name, "patreon"

      option :client_options,
        site: "https://www.patreon.com",
        authorize_url: "/oauth2/authorize",
        token_url: "/api/oauth2/token"

      option :scope, "identity identity[email]"

      uid { raw_info.dig("data", "id") }

      info do
        attrs = raw_info.dig("data", "attributes") || {}
        {
          name: attrs["full_name"],
          email: attrs["email"],
          image: attrs["image_url"]
        }
      end

      extra { { raw_info: raw_info } }

      # OmniAuth's default callback_url appends the request-phase query string
      # (e.g. ?connect_token=...) to the redirect_uri. Patreon validates
      # redirect_uri by exact match against the registered callback and rejects
      # any extra params ("Redirect URI ... is not supported by client"). Return
      # a clean URL instead — the same thing omniauth-google-oauth2 does, which
      # is why Google connects fine. The connect_token still survives the
      # round-trip because OmniAuth stores request params in the session, not the
      # redirect_uri.
      def callback_url
        options[:redirect_uri] || (full_host + script_name + callback_path)
      end

      def raw_info
        @raw_info ||= access_token
          .get("/api/oauth2/v2/identity?fields[user]=email,full_name,image_url")
          .parsed
      end
    end
  end
end
