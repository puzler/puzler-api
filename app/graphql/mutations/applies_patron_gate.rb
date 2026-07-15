module Mutations
  # Shared gate-upsert logic for SetPuzzlePatronGate / SetCollectionPatronGate.
  # A nil gate input clears the row back to the default gate (any paying
  # patron). Tier references must belong to the author's own campaign — the
  # model validates it too, but resolving IDs through the campaign here means
  # foreign IDs simply don't resolve.
  module AppliesPatronGate
    private

    # Returns an error-messages array; empty on success.
    def apply_patron_gate(gateable, gate_input)
      if gate_input.nil?
        gateable.patron_gate&.destroy!
        gateable.association(:patron_gate).reset # the response serializes gateable
        return []
      end

      campaign = current_user.patreon_campaign
      unless campaign&.gating_available?
        return [ "You need a linked Patreon campaign to configure patron gates" ]
      end

      gate = gateable.patron_gate || gateable.build_patron_gate
      gate.mode = gate_input[:mode]
      gate.patrons_since_release = gate_input[:patrons_since_release]
      gate.min_tier = gate.mode_min_tier? ? campaign.tiers.find_by(id: gate_input[:min_tier_id]) : nil
      gate.min_amount_cents = gate.mode_min_amount? ? gate_input[:min_amount_cents] : nil

      if gate.mode_tier_list?
        tiers = campaign.tiers.where(id: gate_input[:tier_ids] || [])
        return [ "Select at least one of your tiers" ] if tiers.empty?

        gate.gate_tiers = tiers.map { |tier| gate.gate_tiers.find { |gt| gt.patreon_tier_id == tier.id } || PatronGateTier.new(patreon_tier: tier) }
      else
        gate.gate_tiers = []
      end

      return gate.errors.full_messages unless gate.save

      # The response serializes gateable.patron_gate; drop the in-memory
      # copies so the through-association (tiers) reads what was just saved.
      gateable.association(:patron_gate).reset
      []
    end
  end
end
