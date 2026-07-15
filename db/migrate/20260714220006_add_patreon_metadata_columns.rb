class AddPatreonMetadataColumns < ActiveRecord::Migration[8.0]
  def change
    # Token lifecycle metadata: Patreon access tokens expire (~31 days); scopes
    # record what the user actually granted so the app can prompt re-auth when
    # patron/creator features need more than they have.
    add_column :user_oauth_identities, :expires_at, :datetime
    add_column :user_oauth_identities, :scopes, :string

    # Viewer preference: hide locked patron-only upsell cards from list surfaces
    # (archive, profiles, feed, collection rows).
    add_column :users, :hide_patron_teasers, :boolean, null: false, default: false
  end
end
