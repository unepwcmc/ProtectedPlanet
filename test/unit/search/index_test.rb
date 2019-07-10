require 'test_helper'

class IndexTest < ActiveSupport::TestCase
  test '.index, given a Model enumerable, PUTs a set of Model records to Elastic Search' do
    elasticsearch_index = "fake_index"

    FactoryGirl.create(:protected_area, name: 'Charlie')
    FactoryGirl.create(:protected_area, name: 'Mac')

    ProtectedArea.any_instance.
      stubs(:as_indexed_json).
      returns(
        {name: 'Charlie'},
        {name: 'Mac'}
      )

    bulk_data = [
      {index: {_index: "#{elasticsearch_index}"}},
      {name: "Charlie"},
      {index: {_index: "#{elasticsearch_index}"}},
      {name: "Mac"}
    ]

    bulk_mock = mock()
    bulk_mock.
      expects(:bulk).
      with(body: bulk_data)
    indices_mock = mock()
    indices_mock.expects(:create).with(any_parameters)

    bulk_mock.stubs(:indices).returns(indices_mock)

    Elasticsearch::Client.stubs(:new).returns(bulk_mock)

    Search::Index.index elasticsearch_index, ProtectedArea.without_geometry
  end

  test 'create creates the index and indexes all desired models' do
    pa_relation =  ProtectedArea.without_geometry.includes([
      {:countries_for_index => :region_for_index},
      :sub_locations,
      :designation,
      :iucn_category
    ])

    Elasticsearch::Client.stubs(:new).
      returns(stub_everything(count: {'count' => 0},
                              indices: stub_everything()
                             ))

    Search::Index.expects(:index).with(Search::COUNTRY_INDEX, Country.without_geometry)
    Search::Index.expects(:index).with(Search::PA_INDEX, pa_relation)

    Search::Index.create
  end

  test '#delete deletes the index' do
    index_name = "fake_index"

    indices_mock = mock()
    indices_mock.expects(:create).with(any_parameters)
    indices_mock.expects(:delete).with(index: index_name)

    es_mock = mock()
    es_mock.stubs(:indices).returns(indices_mock)

    Elasticsearch::Client.stubs(:new).returns(es_mock)

    Search::Index.delete "fake_index"
  end


  test '.count returns the number of documents in the index' do
    es_mock = mock
    indices_mock = mock
    es_mock.expects(:indices).returns(indices_mock)
    es_mock.expects(:count).returns({'count' => 123})
    indices_mock.expects(:create).with(any_parameters)

    Elasticsearch::Client.expects(:new).returns(es_mock)

    assert_equal 123, Search::Index.new("fake_index").count
  end
end
