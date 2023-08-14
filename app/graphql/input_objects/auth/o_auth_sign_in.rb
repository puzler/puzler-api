# frozen_string_literal: true

module InputObjects
  module Auth
    class OAuthSignIn < BaseInputObject
      description 'Payload to sign in with an OAuth provider'

      argument :code,
               String,
               required: true,
               description: 'The Code sent from the OAuth provider to authenticate the user'

      argument :provider_name,
               String,
               required: true,
               description: 'The OAuth provider who sent the code'
    end
  end
end
