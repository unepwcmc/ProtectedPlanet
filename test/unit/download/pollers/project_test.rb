require 'test_helper'

class DownloadPollersProjectTest < ActiveSupport::TestCase
  test '.poll, given a token, returns the current generation info from redis' do
    token = '123'
    key = 'downloads:projects:123:all'
    response_json = '{"status":"generating"}'
    $redis.expects(:get).with(key).returns(response_json)

    assert_equal({'status' => 'generating'}, Download::Pollers::Project.poll(token))
  end
end
