source "https://rubygems.org"

gem "rails", "~> 7.2.3", ">= 7.2.3.1"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false

# Auth
gem "bcrypt", "~> 3.1.7"
gem "devise"
gem "devise-jwt"
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"

# GraphQL
gem "graphql"

# Authorization
gem "pundit"

# Pagination
gem "pagy"

# CORS
gem "rack-cors"

# Redis for Action Cable
gem "redis", ">= 4.0.1"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-graphql", require: false
  gem "rubocop-rspec", require: false
end

group :development do
  gem "annotate"
end

group :test do
  gem "shoulda-matchers"
end
