class DownloadWorkersSearchTest < ActiveSupport::TestCase
  def setup
    Wdpa::S3.stubs(:current_wdpa_identifier).returns('Jun2015')
  end

  test '.perform executes a search and generates a download with the returned
   ids' do
    query_term = 'manbone'
    token = '12345'
    pa_ids = [1,2,3,4]
    digested_pa_ids = '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4'

    saved_search_mock = mock()
    saved_search_mock.stubs(:wdpa_ids).returns(pa_ids)
    saved_search_mock.stubs(:properties).returns({})
    saved_search_mock.stubs(:complete!)
    SavedSearch.expects(:new).
      with(search_term: query_term, filters: '{}').
      returns(saved_search_mock)

    Download.expects(:generate).
      with("WDPA_Jun2015_search_manbone_#{digested_pa_ids}", {wdpa_ids: pa_ids})

    DownloadWorkers::Search.new.perform token, query_term, {}
  end

  test '.perform, given a Search with an email, sends a completion email when the
   download is done' do
    email = "tests@theinternetemail.com"
    pa_ids = [1,2,3,4]
    filename = 'WDPA_Jun2015_search_03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4'
    token = 1234

    saved_search_mock = mock()
    saved_search_mock.stubs(:wdpa_ids).returns(pa_ids)


    SavedSearch.expects(:new).
      with(search_term: '', filters: '{}').
      returns(saved_search_mock)

    Download::Utils.stubs(:properties).returns({'email' => email})
    Download.stubs(:generate)

    mailer_mock = mock().tap { |m| m.expects(:deliver) }
    DownloadCompleteMailer.
      expects(:create).
      with(filename, email).
      returns(mailer_mock)

    DownloadWorkers::Search.new.perform token, '', {}
  end
end
