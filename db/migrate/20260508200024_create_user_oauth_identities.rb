class CreateUserOauthIdentities < ActiveRecord::Migration[7.2]
  def change
    create_table :user_oauth_identities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.text :access_token
      t.text :refresh_token

      t.timestamps
    end

    add_index :user_oauth_identities, [ :provider, :uid ], unique: true
  end
end
