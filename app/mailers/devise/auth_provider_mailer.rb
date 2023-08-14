# frozen_string_literal: true

module Devise
  class AuthProviderMailer < ApplicationMailer
    include Devise::Mailers::Helpers

    def confirm_provider(record, token, opts = {})
      @token = token
      devise_mail(record, :confirm_oauth_provider, opts)
    end

    protected

    def headers_for(action, opts)
      headers = super

      headers[:subject] = I18n.t(
        'devise.mailer.confirm_provider.subject',
        provider: opts[:provider] || 'an OAuth provider'
      )

      headers
    end
  end
end
