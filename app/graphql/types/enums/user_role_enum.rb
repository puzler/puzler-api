# frozen_string_literal: true

module Types
  module Enums
    # Account role — generated from User's `role` enum.
    class UserRoleEnum < BaseEnum
      description "Account role: user or admin"
      generate_from_rails_enum User.roles
    end
  end
end
