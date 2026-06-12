module Mutations
  module Users
    class PrepareOauthConnect < Mutations::BaseMutation
      description "Get a short-lived URL that starts an OAuth flow to connect a " \
                  "provider to the current account. The SPA redirects the browser there."

      # Identity provider names → Devise/OmniAuth route segments.
      PROVIDER_ROUTES = { "google" => "google_oauth2", "patreon" => "patreon" }.freeze

      argument :provider, String, required: true,
        description: "Provider to connect: google or patreon"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :url, String, null: true,
        description: "OAuth authorization URL containing a 5-minute connect token"

      def resolve(provider:)
        require_auth!

        route = PROVIDER_ROUTES[provider]
        return { url: nil, errors: [ "Unknown provider: #{provider}" ] } unless route

        connect_token = Rails.application.message_verifier(:oauth_connect)
          .generate(current_user.id, expires_in: 5.minutes)

        api_url = ENV.fetch("API_URL", "http://localhost:3000")
        { url: "#{api_url}/users/auth/#{route}?connect_token=#{CGI.escape(connect_token)}", errors: [] }
      end
    end
  end
end
