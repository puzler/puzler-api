# Sidekiq runs background jobs (e.g. PrunePlayJob) on a dedicated worker process
# in production, sharing the same Redis instance as Action Cable and the presence
# registry. Connections are configured lazily, so dev/test (which use the :async
# / :test adapters and never call Sidekiq.redis) need no running Redis.
require "sidekiq"

redis_config = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

Sidekiq.configure_server do |config|
  config.redis = redis_config

  # Schedule the hourly backstop sweep. configure_server runs only on the worker,
  # so the schedule is registered once, there — not in web/client processes.
  config.on(:startup) do
    Sidekiq::Cron::Job.load_from_hash!(
      "prune_abandoned_plays" => {
        "cron" => "0 * * * *", # top of every hour
        "class" => "PruneAbandonedPlaysJob"
      },
      # Daily Patreon reconcile: campaign/tier refresh + full member re-mirror.
      # The backstop for missed or paused webhooks.
      "patreon_reconcile" => {
        "cron" => "15 4 * * *",
        "class" => "PatreonReconcileJob"
      }
    )
  end
end

Sidekiq.configure_client { |config| config.redis = redis_config }
