source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in fixture_farm.gemspec.
gemspec

group :development do
  gem 'rubocop'
  gem 'sqlite3'
end

require 'pp'

group :test do
  gem 'fakefs', '~> 3.0', require: 'fakefs/safe'
end
