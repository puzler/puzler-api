# Request throttling. Limits are deliberately generous — the goal is stopping
# credential stuffing and runaway scripts, not rate-limiting enthusiastic
# solvers. Counters live in Redis (same instance as Sidekiq) so limits hold
# across web processes; in test we leave Rack::Attack disabled entirely.
if Rails.env.test?
  Rack::Attack.enabled = false
else
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
    namespace: "rack-attack"
  )

  # Credential stuffing: cap sign-in attempts per IP, and per targeted account
  # (so a distributed attack on one account still trips the limit).
  Rack::Attack.throttle("logins/ip", limit: 20, period: 5.minutes) do |req|
    req.ip if req.post? && req.path == "/users/sign_in"
  end
  Rack::Attack.throttle("logins/email", limit: 10, period: 5.minutes) do |req|
    if req.post? && req.path == "/users/sign_in"
      email = req.params.dig("user", "email").presence
      email&.downcase&.strip
    end
  end

  # Signup + password-reset abuse.
  Rack::Attack.throttle("signups/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/users"
  end
  Rack::Attack.throttle("password_resets/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/users/password"
  end

  # GraphQL volume per IP: roomy enough for a busy solving session (autosaves
  # are debounced client-side), tight enough to stop a runaway mutation loop.
  Rack::Attack.throttle("graphql/ip", limit: 600, period: 5.minutes) do |req|
    req.ip if req.post? && req.path == "/graphql"
  end

  # Standard JSON 429 with a Retry-After hint.
  Rack::Attack.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    retry_after = match_data ? (match_data[:period] - (Time.now.to_i % match_data[:period])) : 60
    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
      [ { errors: [ { message: "Rate limit exceeded. Try again shortly." } ] }.to_json ]
    ]
  end
end
