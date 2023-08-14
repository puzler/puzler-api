# frozen_string_literal: true

module AuthProviders
  class Base
    def self.provider_name
      name.split('::').last
    end

    def provider_name
      self.class.provider_name.downcase
    end

    def get_token(code)
      code
    end

    def get_user(_)
      raise 'Not Implemented'
    end

    def require_email_confirmation?
      true
    end

    protected

    def base_url
      ''
    end

    def build_request(url, params = {})
      uri = URI("#{base_url}#{url}")
      uri.query = params.map { |k, v| "#{k}=#{v}" }.join('&')

      Net::HTTP::Get.new(uri)
    end

    def parse_response(response)
      JSON.parse(response.body).deep_transform_keys(&:to_sym)
    end

    def redirect_uri
      "#{Rails.application.frontend_url}/auth/omni/#{self.class.provider_name.downcase}"
    end
  end
end
