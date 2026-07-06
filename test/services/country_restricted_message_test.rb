# frozen_string_literal: true

require 'test_helper'

class CountryRestrictedMessageTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
  end

  test '.message_for returns the cached full message' do
    country = Country.new(iso_3: 'NZL', name: 'New Zealand')
    country_name = Country.unscoped.find_by(iso_3: 'NZL')&.name || 'NZL'

    message = CountryRestrictedMessage.message_for(country)

    assert_includes message, country_name
    assert_includes message, 'protected areas and/or OECMs'
    assert_includes message, 'data on 1 protected area(s) are'
    refute_match(/and \d+ OECM/, message)
  end

  test 'build_message includes OECMs only when count is positive' do
    message_without_oecms = CountryRestrictedMessage.send(
      :build_message,
      'Testland',
      protected_areas_count: 5,
      oecms_count: 0
    )
    assert_includes message_without_oecms, 'data on 5 protected area(s) are'
    refute_match(/and \d+ OECM/, message_without_oecms)

    message_with_oecms = CountryRestrictedMessage.send(
      :build_message,
      'Testland',
      protected_areas_count: 5,
      oecms_count: 3
    )
    assert_includes message_with_oecms, 'data on 5 protected area(s) and 3 OECM(s) are'
  end

  test '.message_for formats protected area counts correctly' do
    country = Country.new(iso_3: 'CHN', name: 'China')

    message = CountryRestrictedMessage.message_for(country)

    assert_includes message, '2,981 protected area(s)'
  end

  test '.message_for reads the full preprocessed message from cache' do
    country = Country.new(iso_3: 'NZL', name: 'New Zealand')

    CountryRestrictedMessage.message_for(country)
    cached_messages = Rails.cache.read(CountryRestrictedMessage::CACHE_KEY)

    assert_includes cached_messages.keys, 'NZL'
    assert_includes cached_messages['NZL'], 'chooses to restrict some data'
    assert_includes cached_messages['NZL'], '1 protected area(s)'
  end
end
