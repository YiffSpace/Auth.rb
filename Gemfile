# frozen_string_literal: true

source("https://rubygems.org")
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in yiffspace-auth.gemspec.
gemspec

gem("yiffspace", github: "YiffSpace/Gem", branch: "master")

gem("puma")

gem("sqlite3")

gem("sprockets-rails")

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"

group(:development) do
  gem("rubocop", "~> 1.86", require: false)
  gem("rubocop-erb", "~> 0.7.1", require: false)
  gem("rubocop-rails", "~> 2.34", require: false)
  gem("rubocop-yiffspace", "~> 0.0.1", require: false)
end
