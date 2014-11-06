class SearchWorkersDownloaderTest < ActiveSupport::TestCase
  test '.perform executes a search and generates a download with the returned
   ids' do
    query_term = 'manbone'
    token = '12345'
    pa_ids = [1,2,3,4]
    digested_pa_ids = '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4'

    search_mock = mock()
    search_mock.expects(:pluck).with('wdpa_id').returns(pa_ids)
    search_mock.expects(:token=)
    search_mock.stubs(:complete!)
    search_mock.stubs(:properties).returns({})

    ProtectedArea.stubs(:count).returns(100)
    Search.stubs(:find).returns(search_mock)

    Download.expects(:generate).with("search_#{digested_pa_ids}", {wdpa_ids: pa_ids})
    Search.expects(:search).with(query_term, {
      filters: {'type' => 'protected_area'},
      size: 100,
      without_aggregations: true
    }).returns(search_mock)

    SearchWorkers::Downloader.new.perform token, query_term, {}
  end

  test '.perform, given a Search with an email, sends a completion email when the
   download is done' do
    email = "tests@theinternetemail.com"
    pa_ids = [1,2,3,4]
    filename = 'search_03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4'
    token = 1234

    search_mock = mock()
    search_mock.stubs(:pluck).with('wdpa_id').returns(pa_ids)
    search_mock.stubs(:properties).returns({'user_email' => email })
    search_mock.stubs(:token=)
    search_mock.stubs(:complete!)
    Search.stubs(:search).returns(search_mock)
    Search.expects(:find).with(token).returns(search_mock)

    Download.stubs(:generate)

    mailer_mock = mock().tap { |m| m.expects(:deliver) }
    DownloadCompleteMailer.
      expects(:create).
      with(filename, email).
      returns(mailer_mock)

    SearchWorkers::Downloader.new.perform token, "", {}
  end

  test '.perform completes the search updating its status and filename
   properties' do
    digested_pa_ids = '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4'

    properties_mock = mock()
    properties_mock.expects(:[]=).with('filename', "search_#{digested_pa_ids}")
    properties_mock.stubs(:[])

    search_mock = mock()
    search_mock.expects(:token=)
    search_mock.stubs(:properties).returns(properties_mock)
    search_mock.stubs(:pluck).returns([1,2,3,4])
    search_mock.expects(:complete!)

    Search.stubs(:find).returns(search_mock)
    Search.stubs(:search).returns(search_mock)
    Download.stubs(:generate).returns(true)

    SearchWorkers::Downloader.new.perform '12345', 'san guillermo', {}
  end
end
