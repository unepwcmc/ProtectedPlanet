ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# concurrent-ruby 1.3.5 dropped its implicit `require "logger"`, which Active
# Support < 7.1 relies on -- without this, anything that loads Rails dies with
# `uninitialized constant ActiveSupport::LoggerThreadSafeLevel::Logger`.
# This has to live in boot.rb rather than application.rb: `bin/rails` requires
# `rails/commands` (and so Active Support) before application.rb is ever read.
# Can be removed once we are on Rails 7.1+.
require 'logger'
