# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.2'

gem 'graphql', '~> 2.0'
gem 'puma', '~> 5.0'
gem 'pg'
gem 'rails', '~> 7.0.4', '>= 7.0.4.2'

gem 'bootsnap', require: false
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

group :development, :test do
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'rubocop'
end

group :development do
  gem 'spring'
end
