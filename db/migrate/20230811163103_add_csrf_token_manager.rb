class AddCsrfTokenManager < ActiveRecord::Migration[7.0]
  def change
    create_table :csrf_tokens do |t|
      t.string :client_token_id, null: false
      t.string :token, null: false
      t.datetime :exp, null: false
      t.integer :token_type, null: false
    end

    add_index :csrf_tokens, :token, unique: true
  end
end
