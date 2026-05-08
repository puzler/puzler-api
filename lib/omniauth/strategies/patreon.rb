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

      def raw_info
        @raw_info ||= access_token
          .get("/api/oauth2/v2/identity?fields[user]=email,full_name,image_url")
          .parsed
      end
    end
  end
end
