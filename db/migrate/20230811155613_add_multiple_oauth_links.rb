class AddMultipleOauthLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :user_o_auth_providers do |t|
      t.references :user, null: false
      t.string :oauth_id, null: false
      t.integer :provider, null: false
      t.string :confirmation_token, null: true
      t.datetime :confirmed_at, null: true
      t.datetime :confirmation_sent_at, null: true

      t.timestamps
    end

    add_index :user_o_auth_providers, %i[user_id provider], unique: true
    add_index :user_o_auth_providers, %i[provider oauth_id], unique: true

    User.where.not(provider: nil).each do |u|
      UserOAuthProvider.create(
        user_id: u.id,
        provider: u.provider,
        oauth_id: u.uid
      )
    end

    remove_column :users, :provider, :string
    remove_column :users, :uid, :string
  end
end
