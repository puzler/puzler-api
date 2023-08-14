# frozen_string_literal: true

module AuthProviders
  class Google < Base
    def get_token(code)
      send(
        'https://oauth2.googleapis.com/token',
        {
          code:,
          client_id:,
          client_secret:,
          redirect_uri:,
          grant_type: 'authorization_code'
        },
        method: :post
      )[:access_token]
    end

    def get_user(token)
      data = send('https://openidconnect.googleapis.com/v1/userinfo', token:)

      {
        first_name: data[:given_name],
        last_name: data[:family_name],
        email: data[:email],
        id: data[:sub]
      }
    end

    def require_email_confirmation?
      false
    end

    def build_request(url, params = {}, method:)
      case method
      when :get
        super(url, params)
      when :post
        uri = URI("#{base_url}#{url}")
        request = Net::HTTP::Post.new(uri)

        request['Content-Type'] = 'application/x-www-form-urlencoded'
        request.body = params.map { |k, v| "#{k}=#{v}" }.join('&')

        request
      end
    end

    private

    def send(url, params = {}, token: nil, method: :get)
      request = build_request(url, params, method:)
      http = Net::HTTP.new(request.uri.hostname, request.uri.port)
      http.use_ssl = true

      request['Authorization'] = "Bearer #{token}" if token

      parse_response(
        http.request(request)
      )
    end

    def credentials
      Rails.application.credentials.google
    end

    def client_id
      credentials&.app_id || ENV.fetch('GOOGLE_APP_ID', nil)
    end

    def client_secret
      credentials&.app_secret || ENV.fetch('GOOGLE_APP_SECRET', nil)
    end
  end
end
