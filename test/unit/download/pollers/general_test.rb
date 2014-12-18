require 'test_helper'

class DownloadPollersGeneralTest < ActiveSupport::TestCase
  test '.poll, given a token, returns the current generation info from redis' do
    token = 'USA'
    key = 'downloads:general:USA'
    response_json = '{"status":"generating"}'
    $redis.expects(:get).with(key).returns(response_json)

    assert_equal({'status' => 'generating'}, Download::Pollers::General.poll(token))
  end
end
