# frozen_string_literal: true

module AuthProviders
  class Patreon < Base
    def get_token(code)
      params = {
        client_id:,
        client_secret:,
        code:,
        redirect_uri:,
        grant_type: 'authorization_code'
      }

      data = send(
        '/token',
        params,
        method: :post
      )

      data[:access_token]
    end

    def get_user(token)
      user_data = send(
        '/api/current_user',
        token:
      )[:data]

      {
        first_name: user_data[:attributes][:first_name],
        last_name: user_data[:attributes][:last_name],
        email: user_data[:attributes][:email],
        id: user_data[:id]
      }
    end

    protected

    def base_url
      'https://www.patreon.com/api/oauth2'
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

    def send(url, params = {}, method: :get, token: nil)
      request = build_request(url, params, method:)
      request['Authorization'] = "Bearer #{token}" if token

      http = Net::HTTP.new(request.uri.hostname, request.uri.port)
      http.use_ssl = true

      parse_response(
        http.request(request)
      )
    end

    def client_id
      credentials&.app_id || ENV.fetch('PATREON_APP_ID', nil)
    end

    def client_secret
      credentials&.app_secret || ENV.fetch('PATREON_APP_SECRET', nil)
    end

    def credentials
      Rails.application.credentials.patreon
    end
  end
end
