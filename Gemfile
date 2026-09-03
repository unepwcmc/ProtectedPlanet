source 'https://rubygems.org'

gem 'rails', '~> 8.0.0'

# App server. The legacy deploy ran under system-installed Passenger via nginx,
# so no server gem was ever in the bundle — but config/puma.rb has been here all
# along, waiting for one. Containerised deploys need the server in the image.
gem 'puma', '~> 6.4'

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

# Sprockets needs a Sass compiler. comfortable_media_surfer ships its admin
# stylesheet as .scss (plus a whole Bootstrap .scss tree), so `assets:precompile`
# reaches Sprockets::Autoload::Sass, which does a bare `require 'sass'`. The `sass`
# gem left the Gemfile during the Rails upgrade and nothing replaced it, so that
# require raises LoadError.
#
# It went unnoticed because Dockerfile.deploy tolerates the failure
# (`assets:precompile || echo ...`) and developers' bundles still carried stale
# sass/sassc gems from before the upgrade -- so it only surfaced once CI installed
# cleanly from the lockfile.
#
# sassc-rails registers its own SCSS processor, so Sprockets never reaches that
# autoload. Asset-pipeline only: the app's own styles are Tailwind via Vite.
gem 'sassc-rails', '~> 2.1'

# Pulled in by sassc and ruby-vips, never resolved directly. The old lock pinned
# 1.12.1, whose bundled libffi has no arm64-apple-darwin configure target, so
# `bundle install` on an Apple-silicon host fails to build it. 1.17.x builds on
# both arm64-darwin and the linux container.
gem 'ffi', '~> 1.17', '>= 1.17.4'

# Sprockets JS compressor, for the comfortable_media_surfer admin bundle -- the only
# JS still going through the asset pipeline. Uglifier was dropped in its favour:
# uglify-js is ES5-era and its unmaintained wrapper fails opaquely on Node 24 (it
# reads result['error']['message'], nil for the error shape modern Node returns).
# staging already compressed with terser; production now does too.
gem 'terser', '~> 1.2'

# Frontend related gems
gem 'vite_rails', '~> 3.11.1'
gem 'turbo-mount', '~> 0.4.4'
# As of 20Aug2026 When introducing turbo-rails there are issues found for the frontend due to each load is not refresh
# gem 'turbo-rails', '~> 2.0'

group :production, :staging do
#  gem 'unicorn'
  gem 'dalli', '~> 3.2'
  gem 'rack-cache', '~> 1.2'
end
#
group :development do
  gem 'rubocop', '~> 1.90.0'
  gem 'ruby-lsp', '~> 0.26.11'
  # gem 'listen', '~> 3.1.5'
  # gem 'spring-watcher-listen', '~> 2.0.0'
  #
  gem 'web-console', '>= 3.3.0'
  # gem 'listen', '>= 3.0.5', '< 3.2'
  # gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'factory_bot_rails', '~> 6.2' # was factory_girl_rails 4.4 (File.exists?, removed in Ruby 3.2)
  gem 'mocha', '~> 2.7'
  # `assert_template` and `assigns` -- extracted out of Rails core in 5.0.
  gem 'rails-controller-testing'
  gem 'webmock', '~> 3.23', require: false
  # gem 'codeclimate-test-reporter', require: nil
  gem 'simplecov', require: false
  # gem 'simplecov-console'
end

group :test, :development do
  gem 'minitest', '~> 6.0.6'
end

group :test, :development, :staging do 
  gem 'byebug', '~> 13.0.0'
end

gem 'will_paginate', '~> 3.0'

# aws-sdk (the meta-gem) pulls a gem for EVERY AWS service -- 222 of the 423 gems in
# Gemfile.lock, 52% of the bundle, to use one of them. The app touches S3 and nothing
# else: four call sites (lib/modules/s3.rb, lib/modules/wdpa/s3.rb,
# lib/modules/countries_geometry_importer.rb) all use Aws::S3::Resource/Client, and
# config/storage.yml's `service: S3` needs the same gem.
gem 'aws-sdk-s3', '~> 1.0'

gem 'httparty', '~> 0.15.1' # FROM 13 to 15 BREAKING CHANGES

gem 'sidekiq', '~> 7.0'
# Sidekiq 7 dropped its redis-rb dependency (it uses redis-client internally), but the
# app talks to Redis directly via $redis / Redis.new, so require redis-rb explicitly.
gem 'redis', '~> 5.0'
# connection_pool is only ever a transitive dependency (activesupport >= 2.2.5,
# sidekiq >= 2.3.0 -- both open-ended), so bundler happily resolved 3.0.2, which
# is incompatible with Sidekiq 7.x:
#
#   connection_pool 3.0.2  def pop(timeout: 0.5, exception: ..., **)   # keyword-only
#   sidekiq 7.3.9          @sleeper.pop(total)                         # positional
#
# Every job container therefore died in Sidekiq::Scheduled::Poller#initial_wait at
# boot with "ArgumentError: wrong number of arguments (given 1, expected 0)". The
# poller thread never entered its loop, so the scheduled and retry sets were never
# polled: perform_in/perform_at did nothing and no failed job was ever retried,
# silently. Pin to 2.x until we move to Sidekiq 8, which supports connection_pool 3.
gem 'connection_pool', '~> 2.5'

# Replaces the host crontab entry that ran `rake search:reindex` nightly on the
# old server. Schedule lives in Redis so it survives across the job container's
# rolling Kamal deploys, and syncing it on every boot (config/initializers/sidekiq.rb)
# is idempotent even with multiple job replicas.
gem 'sidekiq-cron', '~> 1.12'

gem 'appsignal', '~> 3.3.11'

gem 'dotenv', '~> 2.8' # 0.11 used File.exists?, removed in Ruby 3.2
gem 'dotenv-deployment'

gem 'comfortable_media_surfer', '~> 3.1'
# Pulled in by Comfy, which only asks for >= 5.0.0. Left to itself Bundler picks
# rails-i18n 5.1.3, which caps railties < 6. Force the Rails 6 line.
gem 'rails-i18n', '~> 8.0'
# nokogiri 1.10 does not build on Ruby 3.x; 1.16+ supports Ruby 3.3. Bumping it
# also unblocked loofah, which needs Nokogiri::HTML4 (present since nokogiri 1.12);
# loofah itself needs no explicit entry -- rails-html-sanitizer already floors it.
gem 'nokogiri', '~> 1.16'
