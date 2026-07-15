class RemovePatreonCampaignIdFromPuzzles < ActiveRecord::Migration[8.0]
  # The 2026-06 placeholder column. Real patron gating derives the campaign
  # from the author (users have one campaign), so a per-puzzle copy would only
  # drift. Nothing ever wrote it; the frontend never queried it.
  def change
    remove_column :puzzles, :patreon_campaign_id, :string
  end
end
