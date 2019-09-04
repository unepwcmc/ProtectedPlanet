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
    
    pai = Search::Index.new elasticsearch_index, ProtectedArea.without_geometry
    pai.create
    pai.index
  end

  test 'create only creates the index' do
    index_name = "fake_index"

    indices_mock = mock()
    indices_mock.expects(:create).with(index: index_name, body: JSON.parse(Search::Index::MAPPINGS_TEMPLATE))

    es_mock = mock()
    es_mock.stubs(:indices).returns(indices_mock)

    Elasticsearch::Client.stubs(:new).returns(es_mock)

    fi = Search::Index.new "fake_index"
    fi.create
  end

  test '#delete deletes the index' do
    index_name = "fake_index"

    indices_mock = mock()
    indices_mock.expects(:delete).with(index: index_name)

    es_mock = mock()
    es_mock.stubs(:indices).returns(indices_mock)

    Elasticsearch::Client.stubs(:new).returns(es_mock)

    fi = Search::Index.new "fake_index"
    fi.delete
  end


  test '.count returns the number of documents in the index' do
    es_mock = mock
    indices_mock = mock
    es_mock.expects(:count).returns({'count' => 123})

    Elasticsearch::Client.expects(:new).returns(es_mock)
    
    assert_equal 123, Search::Index.new("fake_index").count
  end
end
