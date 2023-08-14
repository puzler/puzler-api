# frozen_string_literal: true

module AuthProviders
  class Google < Base
    def get_user(token)
      data = send('/userinfo', token:)

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

    protected

    def base_url
      'https://openidconnect.googleapis.com/v1'
    end

    private

    def send(url, token: nil)
      request = build_request(url)
      http = Net::HTTP.new(request.uri.hostname, request.uri.port)
      http.use_ssl = true

      request['Authorization'] = "Bearer #{token}" if token

      parse_response(
        http.request(request)
      )
    end
  end
end
