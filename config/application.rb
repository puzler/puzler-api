require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Api
  class Application < Rails::Application
    config.active_record.query_log_tags_enabled = true
    config.active_record.query_log_tags = [
      # Rails query log tags:
      :application, :controller, :action, :job,
      # GraphQL-Ruby query log tags:
      current_graphql_operation: -> { GraphQL::Current.operation_name },
      current_graphql_field: -> { GraphQL::Current.field&.path },
      current_dataloader_source: -> { GraphQL::Current.dataloader_source_class }
    ]
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    #
    # `omniauth` is ignored because lib/omniauth/strategies/patreon.rb defines
    # OmniAuth::Strategies::Patreon (Zeitwerk would infer "Omniauth" and raise on
    # eager load). It's required explicitly in config/initializers/devise.rb.
    config.autoload_lib(ignore: %w[assets tasks omniauth])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # OAuth provider tokens predating encryption still exist in dev databases;
    # let AR encryption read them until they're rewritten.
    config.active_record.encryption.support_unencrypted_data = true

    # OmniAuth 2.x needs rack.session for its state/CSRF handshake between the
    # request and callback phases; nothing else uses the session (auth is JWT).
    # same_site must stay :lax so the state cookie survives the provider redirect.
    config.session_store :cookie_store, key: "_puzler_session", same_site: :lax
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use config.session_store, config.session_options

    # Browser origins allowed to call the API (CORS) and open Action Cable
    # WebSockets. We accept both the apex and `www` forms of the configured
    # frontend host, since both DNS names resolve to the same SPA and we don't
    # want to care which one the visitor landed on. Driven by the single
    # `FRONTEND_URL` env var, falling back to the Vite dev server locally.
    def frontend_origins
      configured = ENV.fetch("FRONTEND_URL", "http://localhost:5173")
      Array(configured).flat_map { |url| origin_variants(url) }.uniq
    end

    private

    # Expand a URL into its apex + `www` origin variants ("scheme://host[:port]").
    # Bare hosts without a dot (e.g. "localhost") are returned unchanged.
    def origin_variants(url)
      uri = URI(url)
      host = uri.host
      return [ url ] unless host&.include?(".")

      bare = host.delete_prefix("www.")
      port = uri.port && uri.port != uri.default_port ? ":#{uri.port}" : ""
      [ bare, "www.#{bare}" ].map { |h| "#{uri.scheme}://#{h}#{port}" }
    end
  end
end
