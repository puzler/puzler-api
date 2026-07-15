# frozen_string_literal: true

module Types
  module Enums
    class PatreonCampaignStatusEnum < BaseEnum
      description "Health of the mirrored Patreon campaign link"
      generate_from_rails_enum PatreonCampaign.statuses
    end
  end
end
