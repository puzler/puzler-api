# frozen_string_literal: true

module Schemas
  module Auth
    module AuthMutations
      include Interfaces::BaseInterface

      description 'Mutations related to app authentication'

      field :sign_in_with_o_auth,
            mutation: Mutations::Auth::SignInWithOAuth,
            description: 'Used to sign in with a OAuth code'
    end
  end
end
