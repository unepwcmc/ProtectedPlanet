source 'https://rubygems.org'

gem 'rails', '5.2.0'
gem 'webpacker', '~> 4.0.2'

gem 'bourbon'
gem "neat"

gem 'pg', '~> 0.21'
gem 'activerecord-postgis-adapter', '5.1.0'
gem 'dbf', '~> 2.0.7'
#
gem 'elasticsearch', '~> 7.2.0'
#
gem 'sass-rails', '~> 5.0.7'
gem 'sprockets-rails', '~> 3.2.1'

gem 'uglifier', '~> 4.1.17'
gem 'coffee-rails', '~> 4.2.2'
gem "autoprefixer-rails"
gem "exception_notification", '~> 4.3.0'
gem "slack-notifier", "~> 1.5.1"
#
gem 'jquery-rails', '~> 4.3.3'
gem 'premailer-rails'
# gem 'listen'
gem 'levenshtein', '~> 0.2.2'

gem 'vuejs-rails', '~> 2.3.2'
gem 'sprockets-vue', '~> 0.1.0'

gem 'rails-controller-testing'

gem 'gdal', '~> 2.0'
#
group :production, :staging do
#  gem 'unicorn'
  gem 'dalli', '~> 2.7.2'
  gem 'rack-cache', '~> 1.2'
end
#
group :development do
  gem 'spring'
  gem 'capistrano', '3.11.0', require: false
  gem 'capistrano-rails',   '1.4.0', require: false
  gem 'capistrano-bundler', '1.6.0', require: false
  gem 'capistrano-rvm', '0.1.2', require: false
  gem 'capistrano-maintenance','1.2.1', require: false
  gem 'capistrano-passenger', '0.2.0', require: false
  gem 'capistrano-sidekiq','1.0.2'
  gem 'capistrano-git-with-submodules', '2.0.3'
  gem 'capistrano-service'
  gem 'awesome_print'
  gem 'net-sftp'
  # gem 'listen', '~> 3.1.5'
  # gem 'spring-watcher-listen', '~> 2.0.0'
  #
  gem 'web-console', '>= 3.3.0'
  # gem 'listen', '>= 3.0.5', '< 3.2'
  # gem 'spring-watcher-listen', '~> 2.0.0'
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
  gem 'database_cleaner'
end

group :test, :development do
  #gem 'konacha' - TODO - NOT COMPATIBLE WITH RAILS 5
  gem 'ejs'
  # gem 'minitest', '5.10.3' # Explicit minitest version fixes test reporting errors
  gem 'minitest', '~> 5.10', '!= 5.10.2'
  gem 'byebug', '~> 9.0', '>= 9.0.5'

end



gem 'will_paginate', '~> 3.0'

gem 'aws-sdk', '3.0.1' # DRAMATIC CHANGES

gem 'httparty', '~> 0.15.1' # FROM 13 to 15 BREAKING CHANGES
gem 'httmultiparty', '~> 0.3.14'

gem 'sidekiq', '~> 5.2.5' # DRAMATIC CHANGES
gem 'sinatra', '>= 1.3.0', :require => nil
gem 'whenever', require: false

gem 'appsignal', '~> 1.3.6'

gem 'system'
gem 'dotenv', '~> 0.11.1'
gem 'dotenv-deployment'

gem 'best_in_place', '~> 3.0.1'
gem 'turnout', '~> 2.5.0'

gem 'bystander', '2.0.0', git: 'https://github.com/unepwcmc/bystander'

gem 'devise', '~> 4.7.1' # MAJOR VERSION CHANGE, CHECK DOCS

gem 'comfortable_mexican_sofa', '~> 2.0.0'
gem 'nokogiri', '~> 1.10.4'
gem 'tinymce-rails', '~> 4.3.2'
gem 'phantompdf', '~> 1.2.2'
