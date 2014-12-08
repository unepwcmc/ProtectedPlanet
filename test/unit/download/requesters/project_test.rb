require 'test_helper'

class DownloadRequesterProjectTest < ActiveSupport::TestCase
  test '#request checks for infos on the project on redis, and returns the
   content' do
    project_properties = {token:'123', status: 'generating'}.to_json

    project = FactoryGirl.create(:project)
    $redis.stubs(:get).
      with("downloads:projects:#{project.id}:all").
      returns(project_properties)

    requester = Download::Requesters::Project.new project.id
    assert_equal({'token' => '123', 'status' => 'generating'}, requester.request)
  end
end
