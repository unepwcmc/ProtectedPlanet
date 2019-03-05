source 'https://rubygems.org'

gem 'rails', '4.2.11'

gem 'pg', '~> 0.21'
gem 'activerecord-postgis-adapter', '~> 3.1.0'
gem 'gdal', '~> 1.0.0'
gem 'dbf', '~> 2.0.7'

gem 'elasticsearch', '~> 5.0.3'

gem 'bower-rails', '~> 0.10.0'
gem 'sass-rails', '~> 5.0.4'
gem 'sprockets-rails', '~> 2.3.3'
gem 'uglifier', '~> 2.7.2'
gem 'coffee-rails', '~> 4.0.0'
gem "autoprefixer-rails"
gem "exception_notification", '~> 4.1.4'
gem "slack-notifier", "~> 1.5.1"

gem 'jquery-rails', '~> 3.1.3'
gem 'premailer-rails'

gem 'levenshtein', '~> 0.2.2'

gem 'vuejs-rails', '~> 2.3.2'
gem 'sprockets-vue', '~> 0.1.0'

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
  gem 'webmock', '~> 1.22.0', require: false
  gem 'timecop', '~> 0.7.1'
  gem 'capybara', '~> 2.3.0'
  # gem 'codeclimate-test-reporter', require: nil
  gem 'simplecov', require: false, group: :test
  # gem 'simplecov-console'
  gem 'selenium-webdriver'
end

group :test, :development do
  gem 'konacha'
  gem 'ejs'
end

gem 'will_paginate', '~> 3.0'

gem 'aws-sdk', '~> 1.3.9'

gem 'httparty', '~> 0.13.1'
gem 'httmultiparty', '~> 0.3.14'

gem 'sidekiq', '~> 4.0.0'
gem 'sinatra', '>= 1.3.0', :require => nil
gem 'whenever', require: false

gem 'appsignal', '~> 1.3.6'

gem 'system'
gem 'dotenv', '~> 0.11.1'
gem 'dotenv-deployment'

gem 'best_in_place'
gem 'turnout', '~> 2.0.0'
gem 'bystander', git: 'https://github.com/unepwcmc/bystander'

gem 'devise', '~> 3.5.2'

gem 'comfortable_mexican_sofa', '~> 1.12.8'
gem 'nokogiri', '~> 1.6.7'
gem 'tinymce-rails', '~> 4.3.2'
gem 'phantompdf', '~> 1.2.2'
