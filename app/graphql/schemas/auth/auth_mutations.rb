# frozen_string_literal: true

module Schemas
  module Auth
    module AuthMutations
      include Interfaces::BaseInterface

      description 'Mutations related to app authentication'

      field :sign_in_with_o_auth,
            mutation: Mutations::Auth::SignInWithOAuth,
            description: 'Used to sign in with a OAuth code'

      field :sign_in,
            mutation: Mutations::Auth::SignIn,
            description: 'Used to sign in with email and password'

      field :sign_up,
            mutation: Mutations::Auth::SignUp,
            description: 'Used to sign up as a User'

      field :confirm_email,
            mutation: Mutations::Auth::ConfirmEmail,
            description: 'Used to confirm an email with a token'

      field :request_password_reset,
            mutation: Mutations::Auth::RequestPasswordReset,
            description: "Used to request an email with a token used to reset a User's password"

      field :reset_password,
            mutation: Mutations::Auth::ResetPassword,
            description: 'Used to reset a password with a token'
    end
  end
end
