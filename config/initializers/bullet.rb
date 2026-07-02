# N+1 query detection. Logs (dev) and raises (test) so a missing includes or
# an unbatched association can't ship quietly. Fix findings by batching (the
# GraphQL layer has Dataloader sources for cross-row cases) — never by adding
# an allowlist entry here without a comment explaining why it's a false positive.
if defined?(Bullet)
  Rails.application.configure do
    config.after_initialize do
      case Rails.env
      when "development"
        Bullet.enable = true
        Bullet.bullet_logger = true
        Bullet.rails_logger = true
      when "test"
        Bullet.enable = true
        Bullet.raise = true
      end

      if Bullet.enable?
        # Unused-eager-loading detection is off: GraphQL resolvers eager-load
        # speculatively (which associations get used depends on the query's
        # field selection), so "unused includes" is usually a false positive
        # for one selection shape and load-bearing for another.
        Bullet.unused_eager_loading_enable = false
      end
    end
  end
end
