# frozen_string_literal: true

module Schemas
  module Auth
    module AuthMutations
      include Interfaces::BaseInterface

      field :sign_in_with_o_auth, mutation: Mutations::Auth::SignInWithOAuth
    end
  end
end
