require 'test_helper'

class ImportToolsMaintenanceSwitcherTest < ActiveSupport::TestCase
  test '#on creates a new instance of MaintenanceSwitcher' do
    ImportTools::MaintenanceSwitcher.expects(:new).returns(stub_everything)
    ImportTools::MaintenanceSwitcher.on
  end

  test '#off creates a new instance of MaintenanceSwitcher' do
    ImportTools::MaintenanceSwitcher.expects(:new).returns(stub_everything)
    ImportTools::MaintenanceSwitcher.off
  end

  test '#on does an HTTP call to the maintenance url' do
    key = Rails.application.secrets.maintenance_mode_key

    fake_url = 'http://example.com/maintenance'
    ImportTools::MaintenanceSwitcher.any_instance.stubs(:url_for).returns(fake_url)

    HTTParty.expects(:put).with(
      fake_url,
      query: {maintenance_mode_on: true},
      headers: {'X-Auth-Key' => key}
    )
    ImportTools::MaintenanceSwitcher.on
  end

  test '#off does an HTTP call to the maintenance url' do
    key = Rails.application.secrets.maintenance_mode_key

    fake_url = 'http://example.com/maintenance'
    ImportTools::MaintenanceSwitcher.any_instance.stubs(:url_for).returns(fake_url)

    HTTParty.expects(:put).with(
      fake_url,
      query: {maintenance_mode_on: false},
      headers: {'X-Auth-Key' => key}
    )
    ImportTools::MaintenanceSwitcher.off
  end
end
