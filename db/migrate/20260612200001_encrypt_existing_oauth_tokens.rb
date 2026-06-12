class EncryptExistingOauthTokens < ActiveRecord::Migration[8.0]
  def up
    # #encrypt rewrites plaintext attribute values in their encrypted form
    # (a same-value update! would be skipped as a no-op change).
    UserOauthIdentity.reset_column_information
    UserOauthIdentity.find_each(&:encrypt)
  end

  def down
    # Values remain readable thanks to support_unencrypted_data; nothing to do.
  end
end
