require 'test_helper'

class DownloadRequesterGeneralTest < ActiveSupport::TestCase
  test '#request checks for the general download on redis, and returns the
   content' do
    token = '123'
    download_properties = {token: token, status: 'completed'}.to_json

    $redis.expects(:get).
      with("downloads:general:#{token}").
      returns(download_properties).
      twice

    requester = Download::Requesters::General.new 'shp', token
    assert_equal({'token' => '123', 'status' => 'completed'}, requester.request)
  end
end
