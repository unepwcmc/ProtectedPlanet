require 'test_helper'

class DownloadRequesterGeneralTest < ActiveSupport::TestCase
  # #request no longer returns the raw redis properties: it builds a payload of
  # id / title / url / hasFailed / token from the stored generation info.
  # "ready" (not "completed") is the status that marks a generation finished.
  test '#request returns the download payload built from the stored generation info' do
    token = '123'
    generation_info = { status: 'ready', filename: 'WDPA_general_123.zip' }.to_json

    $redis.stubs(:get).with("downloads:general:shp:#{token}").returns(generation_info)

    response = Download::Requesters::General.new('shp', token).request

    assert_equal "#{token}-shp", response['id']
    assert_equal 'WDPA_general_123.zip', response['title']
    assert_equal token, response['token']
  end
end
