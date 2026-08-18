source 'https://rubygems.org'

gem 'rails', '~> 8.0.0'

# Ruby 3.1+ ships Psych 4/5, whose load is safe-load (aliases off). Rails 7 loads
# its own configs (database.yml, secrets) alias-aware, but webpacker 4 and
# appsignal 3 call plain YAML.load on their aliased configs at boot and break.
# Pin Psych 3 until those are gone -- webpacker at the Vite cutover (B5),
# appsignal on a version bump. (libyaml-dev is present in the image.)
gem 'psych', '~> 3.3'

gem 'pg', '~> 1.1'
gem 'activerecord-postgis-adapter', '~> 11.0'
gem 'dbf', '~> 2.0.7'
#
# Match the 7.17.24 server. Stay on the ES 7.x client — 8.x is a client rewrite
# (elastic-transport gem, namespace changes) and the code uses
# Elasticsearch::Transport::Transport::Errors::*, which 7.17 keeps and 8.x drops.
gem 'elasticsearch', '~> 7.17'
# elasticsearch-transport 7.17 rides on Faraday; pin the 1.x line (2.x split the
# adapters into separate gems). 1.10 is the last 1.x and Ruby 3.3-clean.
gem 'faraday', '~> 1.10'
#
gem 'sprockets-rails', '~> 3.2'

gem 'uglifier', '~> 4.1.17'
gem "autoprefixer-rails"
gem "exception_notification", '~> 4.5' # 4.3 caps actionmailer < 6
gem "slack-notifier", "~> 1.5.1"
#
gem 'jquery-rails', '~> 4.3.3'
gem 'premailer-rails'
# gem 'listen'
gem 'levenshtein', '~> 0.2.2'

gem 'rails-controller-testing'

gem 'gdal', '~> 2.0'
gem 'net-sftp'
gem 'net-scp'

# Frontend related gems
gem 'vite_rails', '~> 3.11.1'
gem 'turbo-mount', '~> 0.4.4'
gem 'turbo-rails', '~> 2.0'

group :production, :staging do
#  gem 'unicorn'
  gem 'dalli', '~> 3.2'
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
  gem 'capistrano-sidekiq', '1.0.2'
  gem 'capistrano-git-with-submodules', '2.0.3'
  gem 'capistrano-service'
  gem 'awesome_print'
  # gem 'rubocop', '~> 0.80.0'
  # gem 'listen', '~> 3.1.5'
  # gem 'spring-watcher-listen', '~> 2.0.0'
  #
  gem 'web-console', '>= 3.3.0'
  # gem 'listen', '>= 3.0.5', '< 3.2'
  # gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'factory_bot_rails', '~> 6.2' # was factory_girl_rails 4.4 (File.exists?, removed in Ruby 3.2)
  gem 'webrick' # removed from Ruby 3's default gems; used by the S3 upload test
  gem 'mocha', '~> 2.7'
  gem 'webmock', '~> 3.23', require: false
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
  # gem 'minitest', '5.10.3' # Explicit minitest version fixes test reporting errors
  gem 'minitest', '~> 5.10', '!= 5.10.2', '< 5.26.2' # 5.26.2+ requires ruby >= 3.1
  

end

group :test, :development, :staging do 
  gem 'byebug', '~> 9.0', '>= 9.0.5'
end



gem 'will_paginate', '~> 3.0'

gem 'aws-sdk', '3.0.1' # DRAMATIC CHANGES

gem 'httparty', '~> 0.15.1' # FROM 13 to 15 BREAKING CHANGES
gem 'httmultiparty', '~> 0.3.14'

gem 'sidekiq', '~> 7.0'
# Sidekiq 7 dropped its redis-rb dependency (it uses redis-client internally), but the
# app talks to Redis directly via $redis / Redis.new, so require redis-rb explicitly.
gem 'redis', '~> 5.0'
gem 'sinatra', '>= 1.3.0', :require => nil
gem 'whenever', require: false

gem 'appsignal', '~> 3.3.11'

gem 'system'
gem 'dotenv', '~> 2.8' # 0.11 used File.exists?, removed in Ruby 3.2
gem 'dotenv-deployment'

gem 'turnout', '~> 2.5.0'

gem 'bystander', '2.0.0', git: 'https://github.com/unepwcmc/bystander'

gem 'comfortable_media_surfer', '~> 3.1'
# Pulled in by Comfy, which only asks for >= 5.0.0. Left to itself Bundler picks
# rails-i18n 5.1.3, which caps railties < 6. Force the Rails 6 line.
gem 'rails-i18n', '~> 8.0'
# nokogiri 1.10 does not build on Ruby 3.x; 1.16+ supports Ruby 3.3. Bumping it
# also unblocks loofah (needs Nokogiri::HTML4, present since nokogiri 1.12).
gem 'nokogiri', '~> 1.16'
gem 'loofah', '~> 2.22'
gem 'phantompdf', '~> 1.2.2'
gem 'bcrypt_pbkdf', '>= 1.0', '< 2.0'
gem 'ed25519', '>= 1.2', '< 2.0'