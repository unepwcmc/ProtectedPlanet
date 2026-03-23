# frozen_string_literal: true

# Minimal Rails boot for contract tests.
# These tests run against pp_development (where FDW foreign tables and the
# staging_portal_* materialized views live). They intentionally bypass the
# normal test DB setup so that maintain_test_schema! is never triggered and
# no fixtures or DatabaseCleaner are involved.
ENV['RAILS_ENV'] ||= 'development'

require File.expand_path('../../../config/environment', __FILE__)
require 'minitest/autorun'
