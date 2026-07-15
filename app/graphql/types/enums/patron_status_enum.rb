# frozen_string_literal: true

module Types
  module Enums
    class PatronStatusEnum < BaseEnum
      description "The member's standing on Patreon: active, payment-declined, or former"
      generate_from_rails_enum PatreonMembership.patron_statuses
    end
  end
end
