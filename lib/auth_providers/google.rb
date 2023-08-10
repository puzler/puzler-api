# frozen_string_literal: true

module AuthProviders
  class Google
    def get_token(code)
      code
    end

    def get_user(token)
      data = send('https://openidconnect.googleapis.com/v1/userinfo', token:)

      {
        name: data[:name],
        email: data[:email],
        id: data[:sub]
      }
    end

    def send(url, token: nil)
      request = build_request(url)
      http = Net::HTTP.new(request.uri.hostname, request.uri.port)
      http.use_ssl = true

      request['Authorization'] = "Bearer #{token}" if token

      parse_response(
        http.request(request)
      )
    end

    def build_request(url)
      uri = URI(url)

      Net::HTTP::Get.new(uri)
    end

    def parse_response(response)
      JSON.parse(response.body).transform_keys(&:to_sym)
    end

    def credentials
      Rails.application.credentials.google
    end
  end
end
