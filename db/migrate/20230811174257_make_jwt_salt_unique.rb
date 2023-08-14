class MakeJwtSaltUnique < ActiveRecord::Migration[7.0]
  def change
    add_index :users, :jwt_salt, unique: true
  end
end
