# frozen_string_literal: true

module AuthProviders
  class Facebook
    def access_token(code)
      send(
        '/oauth/access_token',
        {
          client_id:,
          client_secret:,
          code:,
          redirect_uri:
        }
      )
    end

    def get_user(token)
      send(
        '/me',
        {
          access_token: token,
          fields: 'id,name,email'
        }
      )
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

    def build_request(url, params)
      uri = URI("#{base_url}#{url}")
      uri.query = params.map { |k, v| "#{k}=#{v}" }.join('&')

      Net::HTTP::Get.new(uri)
    end

    def parse_response(response)
      JSON.parse(response.body).transform_keys(&:to_sym)
    end

    def redirect_uri
      base_url = Rails.env.development? ? 'http://localhost:5173' : 'https://www.puzler.app'
      "#{base_url}/auth/omni/facebook"
    end

    def base_url
      'https://graph.facebook.com/v17.0'
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
