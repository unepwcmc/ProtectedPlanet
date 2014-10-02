source 'https://rubygems.org'

gem 'rails', '4.1.0'
gem 'pg'

gem 'sass-rails', '~> 4.0.3'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'therubyracer',  platforms: :ruby

gem 'jquery-rails'
gem 'turbolinks'

group :production, :staging do
  gem 'unicorn'
  gem 'dalli', '~> 2.7.2'
  gem 'rack-cache', '~> 1.2'
end

group :development do
  gem 'spring'
  gem 'capistrano',  '~> 3.1'
  gem 'capistrano-rails', '~> 1.1'
  gem 'capistrano-bundler', '~> 1.1', require: false
  gem 'capistrano-sidekiq', '~> 0.3.3'
end

group :test do
  gem 'factory_girl_rails', '~> 4.4.1'
  gem 'mocha', '~> 1.0.0'
  gem 'webmock', '~> 1.18.0', require: false
  gem 'timecop', '~> 0.7.1'
  gem 'capybara', '~> 2.3.0'
  gem 'codeclimate-test-reporter', require: nil
end

group :test, :development do
  gem 'konacha'
  gem 'ejs'
end

gem 'elasticsearch', '~> 1.0.4'

gem 'will_paginate', '~> 3.0'

gem 'aws-sdk', '~> 1.3.9'

gem 'activerecord-postgis-adapter', '~>2.0.1'
gem 'gdal', '~> 0.0.5'
gem 'dbf', '~> 2.0.7'

gem 'httparty', '~> 0.13.1'
gem 'httmultiparty', '~> 0.3.14'

gem 'sidekiq', '~> 3.1.4'
gem 'whenever', require: false
gem 'raygun4ruby'

gem 'system'
gem 'dotenv', '~> 0.11.1'
gem 'dotenv-deployment'

gem 'turnout', '~> 2.0.0'

# For debugging
# gem 'byebug', group: [:development, :test]
