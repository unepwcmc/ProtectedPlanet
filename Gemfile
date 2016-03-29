source 'https://rubygems.org'

gem 'rails', '4.1.11'
gem 'pg'

gem 'sass-rails', '~> 4.0.3'
gem 'uglifier', '~> 2.7.2'
gem 'coffee-rails', '~> 4.0.0'
gem 'therubyracer',  platforms: :ruby
gem "autoprefixer-rails"
gem "exception_notification", '~> 4.1.4'
gem "slack-notifier", "~> 1.5.1"

gem 'jquery-rails', '~> 3.1.3'
gem 'neat'
gem 'premailer-rails'

group :production, :staging do
#  gem 'unicorn'
  gem 'dalli', '~> 2.7.2'
  gem 'rack-cache', '~> 1.2'
end

group :development do
  gem 'spring'
  gem 'capistrano', '~> 3.4', require: false
  gem 'capistrano-rails',   '~> 1.1', require: false
  gem 'capistrano-bundler', '~> 1.1.4', require: false
  gem 'capistrano-rvm',   '~> 0.1', require: false
  gem 'capistrano-sidekiq'
  gem 'capistrano-maintenance', '~> 1.0', require: false
  gem 'capistrano-passenger', '~> 0.2.0', require: false
  gem 'byebug', '~> 3.1.2'
end

group :test do
  gem 'factory_girl_rails', '~> 4.4.1'
  gem 'mocha', '~> 1.0.0'
  gem 'webmock', '~> 1.18.0', require: false
  gem 'timecop', '~> 0.7.1'
  gem 'capybara', '~> 2.3.0'
  gem 'codeclimate-test-reporter', require: nil
  gem 'selenium-webdriver'
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

gem 'sidekiq', '~> 3.5.3'
gem 'whenever', require: false

gem 'newrelic_rpm'

gem 'system'
gem 'dotenv', '~> 0.11.1'
gem 'dotenv-deployment'

gem 'best_in_place'

gem 'turnout', '~> 2.0.0'

gem 'sinatra', '>= 1.3.0', :require => nil

gem 'devise', '~> 3.4.0'

gem 'bystander', :git => 'git@github.com:unepwcmc/bystander.git'

