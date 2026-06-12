GraphiQL::Rails.config.tap do |config|
  config.title = "Puzler API Explorer"
  # We authenticate with Bearer JWTs, not cookies — the header editor is how
  # you supply an Authorization header. Persist it across reloads/tabs.
  config.header_editor_enabled = true
  config.should_persist_headers = true
end
