require 'test_helper'
class DownloadWorkersSearchTest < ActiveSupport::TestCase
  def setup
    Wdpa::S3.stubs(:current_wdpa_identifier).returns('Jun2015')
  end

  test '.perform executes a search and generates a download with the returned
   ids' do
    query_term = 'manbone'
    token = '12345'
    pa_ids = [1, 2, 3, 4]
    digested_pa_ids = '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4'

    saved_search_mock = mock
    saved_search_mock.stubs(:site_ids).returns(pa_ids)
    saved_search_mock.stubs(:properties).returns({})
    saved_search_mock.stubs(:complete!)
    SavedSearch.expects(:new)
      .with(search_term: query_term, filters: '{}')
      .returns(saved_search_mock)

    Download.expects(:generate)
      .with("WDPA_Jun2015_search_manbone_#{digested_pa_ids}", { site_ids: pa_ids })

    DownloadWorkers::Search.new.perform token, query_term, {}.to_json
  end

  test '.perform executes a search and generates a download with no search term' do
    token = '12345'
    pa_ids = [1, 2, 3, 4]
    digested_pa_ids = '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4'

    saved_search_mock = mock
    saved_search_mock.stubs(:site_ids).returns(pa_ids)
    saved_search_mock.stubs(:properties).returns({})
    saved_search_mock.stubs(:complete!)
    SavedSearch.expects(:new)
      .with(search_term: nil, filters: '{}')
      .returns(saved_search_mock)

    Download.expects(:generate)
      .with("WDPA_Jun2015_search_#{digested_pa_ids}", { site_ids: pa_ids })

    DownloadWorkers::Search.new.perform token, nil, {}.to_json
  end

  test '.perform executes a search and generates a download with no search term but with a filter' do
    token = '12345'
    pa_ids = [555_556_053,
      555_556_054,
      555_556_055,
      555_556_056,
      317_192,
      317_194,
      317_193,
      3213,
      555_556_061,
      555_556_057,
      555_558_408,
      555_556_058,
      555_558_409,
      555_558_410,
      555_556_052,
      2321,
      555_556_062,
      555_556_063,
      555_556_059,
      555_556_060,
      555_556_064,
      2325,
      555_556_065,
      555_556_067,
      555_556_066,
      2327,
      317_195,
      5086,
      20_171,
      902_264]
    digested_pa_ids = '0ea0447f338935df9c9fe09cd1dd035ed3ad69f4d26e7ae50f8a1c0dec96cc8e'

    saved_search_mock = mock
    saved_search_mock.stubs(:site_ids).returns(pa_ids)
    saved_search_mock.stubs(:properties).returns({})
    saved_search_mock.stubs(:complete!)
    SavedSearch.expects(:new)
      .with(search_term: nil, filters: '{"country":"PER"}')
      .returns(saved_search_mock)

    Download.expects(:generate)
      .with("WDPA_Jun2015_search_#{digested_pa_ids}", { site_ids: pa_ids })

    DownloadWorkers::Search.new.perform token, nil, { country: 'PER' }.to_json
  end

  test '.perform, given a Search with an email, sends a completion email when the
   download is done' do
    email = 'tests@theinternetemail.com'
    pa_ids = [1, 2, 3, 4]
    filename = 'WDPA_Jun2015_search_03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4'
    token = 1234

    saved_search_mock = mock
    saved_search_mock.stubs(:site_ids).returns(pa_ids)

    SavedSearch.expects(:new)
      .with(search_term: '', filters: '{}')
      .returns(saved_search_mock)

    Download::Utils.stubs(:properties).returns({ 'email' => email })
    Download.stubs(:generate)

    mailer_mock = mock.tap { |m| m.expects(:deliver) }
    DownloadCompleteMailer
      .expects(:create)
      .with(filename, email)
      .returns(mailer_mock)

    DownloadWorkers::Search.new.perform token, '', {}.to_json
  end
end
