# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

gem 'bugsnag'
gem 'devise', '~> 4.9'
gem 'graphql', '~> 2.0'
gem 'jwt', '~> 2.7'
gem 'omniauth', '~> 2.1'
gem 'omniauth-facebook', '~> 9.0'
gem 'omniauth-rails_csrf_protection', '~> 1.0'
gem 'pg'
gem 'puma', '~> 5.0'
gem 'rack-cors', '~> 2.0'
gem 'rails', '~> 7.0.4', '>= 7.0.4.2'

gem 'bootsnap', require: false
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

group :development, :test do
  gem 'byebug'
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails'
  gem 'rspec-rails', '~> 6.0.0'
  gem 'rubocop'
  gem 'rubocop-graphql'
  gem 'rubocop-rails'
end

group :development do
  gem 'spring'
end
