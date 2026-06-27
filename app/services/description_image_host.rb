require "uri"

# Single source of truth for where puzzle-description images live. The upload
# mutation builds blob URLs on this host; the sanitizer allows <img> only from
# it. Keeping both anchored here prevents an allow/serve host mismatch.
module DescriptionImageHost
  module_function

  def base_url
    ENV.fetch("API_URL", "http://localhost:3000")
  end

  # Hostnames permitted as <img> sources in a saved description.
  def allowed
    [ URI(base_url).host ].compact
  end
end
