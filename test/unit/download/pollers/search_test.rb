require 'test_helper'

class DownloadPollersSearchTest < ActiveSupport::TestCase
  test '.poll, given a token, returns the current generation info from redis' do
    token = '123'
    key = 'downloads:searches:123'
    response_json = '{"status":"generating"}'
    $redis.expects(:get).with(key).returns(response_json)

    assert_equal({'status' => 'generating'}, Download::Pollers::Search.poll(token))
  end
end

