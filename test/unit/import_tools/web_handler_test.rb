require 'test_helper'

class ImportToolsWebHandlerTest < ActiveSupport::TestCase
  test '#maintenance_on creates a new instance of WebHandler' do
    ImportTools::WebHandler.expects(:new).returns(stub_everything)
    ImportTools::WebHandler.maintenance_on
  end

  test '#maintenance_off creates a new instance of WebHandler' do
    ImportTools::WebHandler.expects(:new).returns(stub_everything)
    ImportTools::WebHandler.maintenance_off
  end

  test '#clear_cache creates a new instance of WebHandler' do
    ImportTools::WebHandler.expects(:new).returns(stub_everything)
    ImportTools::WebHandler.clear_cache
  end

  test '#maintenance_on does an HTTP call to the maintenance url' do
    key = Rails.application.secrets.maintenance_mode_key

    fake_url = 'http://example.com/maintenance'
    ImportTools::WebHandler.any_instance.stubs(:url_for).returns(fake_url)

    HTTParty.expects(:put).with(
      fake_url,
      query: {maintenance_mode_on: true},
      headers: {'X-Auth-Key' => key}
    )
    ImportTools::WebHandler.maintenance_on
  end

  test '#maintenance_off does an HTTP call to the maintenance url' do
    key = Rails.application.secrets.maintenance_mode_key

    fake_url = 'http://example.com/maintenance'
    ImportTools::WebHandler.any_instance.stubs(:url_for).returns(fake_url)

    HTTParty.expects(:put).with(
      fake_url,
      query: {maintenance_mode_on: false},
      headers: {'X-Auth-Key' => key}
    )
    ImportTools::WebHandler.maintenance_off
  end

  test '#under_maintenance switches the maintenance mode twice, and yields in between' do
    ImportTools::WebHandler.expects(:maintenance_on)
    ImportTools::WebHandler.expects(:maintenance_off)

    block_executed = false
    ImportTools::WebHandler.under_maintenance { block_executed = true }

    assert block_executed
  end

  test '#clear_cache does an HTTP call to the clear_cache url' do
    key = Rails.application.secrets.maintenance_mode_key

    fake_url = 'http://example.com/clear_cache'
    ImportTools::WebHandler.any_instance.stubs(:url_for).returns(fake_url)

    HTTParty.expects(:put).with(
      fake_url,
      query: {},
      headers: {'X-Auth-Key' => key}
    )
    ImportTools::WebHandler.clear_cache
  end
end
