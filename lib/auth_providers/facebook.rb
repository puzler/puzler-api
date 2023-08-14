# frozen_string_literal: true

module AuthProviders
  class Facebook < Base
    def get_token(code)
      send(
        '/oauth/access_token',
        {
          client_id:,
          client_secret:,
          code:,
          redirect_uri:
        }
      )[:access_token]
    end

    def get_user(token)
      data = send(
        '/me',
        {
          access_token: token,
          fields: 'id,name,email'
        }
      )

      name_parts = data[:name].split
      {
        id: data[:id],
        email: data[:email],
        first_name: name_parts.first,
        last_name: name_parts[1..].join(' ')
      }
    end

    def require_email_confirmation?
      false
    end

    protected

    def base_url
      'https://graph.facebook.com/v17.0'
    end

    private

    def send(url, params)
      return if client_id.nil? || client_secret.nil?

      request = build_request(url, params)
      http = Net::HTTP.new(request.uri.hostname, request.uri.port)
      http.use_ssl = true

      parse_response(
        http.request(request)
      )
    end

    def client_id
      credentials&.dig(:app_id) || ENV.fetch('FACEBOOK_APP_ID', nil)
    end

    def client_secret
      credentials&.dig(:app_secret) || ENV.fetch('FACEBOOK_APP_SECRET', nil)
    end

    def credentials
      Rails.application.credentials.facebook
    end
  end
end
