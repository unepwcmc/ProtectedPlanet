require 'test_helper'

class DownloadRequestersBaseTest < ActiveSupport::TestCase
  test '.request initializes a new instance of the requester with
   the given args and calls the request method on it' do
    requester_mock = mock
    requester_mock.expects(:request)

    Download::Requesters::Base.
      expects(:new).
      with("arg1", "arg2").
      returns(requester_mock)

    Download::Requesters::Base.request "arg1", "arg2"
  end
end
