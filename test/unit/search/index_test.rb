require 'test_helper'

class IndexTest < ActiveSupport::TestCase
  test '.index, given a Model enumerable, PUTs a set of Model records to Elastic Search' do
    elasticsearch_index = Rails.application.secrets.elasticsearch["index"]

    FactoryGirl.create(:protected_area, name: 'Charlie')
    FactoryGirl.create(:protected_area, name: 'Mac')

    ProtectedArea.any_instance.
      stubs(:as_indexed_json).
      returns(
        {name: 'Charlie'},
        {name: 'Mac'}
      )

    bulk_data = [
      {index: {_index: "#{elasticsearch_index}",_type: "protected_area"}},
      {name: "Charlie"},
      {index: {_index: "#{elasticsearch_index}",_type: "protected_area"}},
      {name: "Mac"}
    ]

    bulk_mock = mock()
    bulk_mock.
      expects(:bulk).
      with(body: bulk_data)
    Elasticsearch::Client.stubs(:new).returns(bulk_mock)

    Search::Index.index ProtectedArea.without_geometry
  end

  test '#create creates the index and indexes all desired models' do
    pa_relation =  ProtectedArea.without_geometry.includes([
      {:countries_for_index => :region_for_index},
      :sub_locations,
      :designation,
      :iucn_category
    ])

    Elasticsearch::Client.stubs(:new).returns(stub_everything)

    Search::Index.expects(:index).with(Country.without_geometry)
    Search::Index.expects(:create_mapping).with('protected_area')
    Search::Index.expects(:index).with(pa_relation)

    Search::Index.create
  end

  test '#delete deletes the index' do
    index_name = Rails.application.secrets.elasticsearch['index']

    indices_mock = mock()
    indices_mock.expects(:delete).with(index: index_name)

    es_mock = mock()
    es_mock.stubs(:indices).returns(indices_mock)

    Elasticsearch::Client.stubs(:new).returns(es_mock)

    Search::Index.delete
  end

  test '#create_mapping reads from an external JSON and sends the mapping to ES' do
    mappings = {'protected_area' => ['id', 'name', 'original_name'], 'country' => ['id', 'name']}
    JSON.expects(:parse).returns(mappings)

    type = 'protected_area'
    index_name = Rails.application.secrets.elasticsearch['index']

    indices_mock = mock()
    indices_mock.expects(:put_mapping).with({
      index: index_name,
      type: type,
      body: {
        'protected_area' => mappings['protected_area']
      }
    })

    es_mock = mock()
    es_mock.stubs(:indices).returns(indices_mock)

    Elasticsearch::Client.stubs(:new).returns(es_mock)

    Search::Index.create_mapping type
  end

  test '.count returns the number of documents in the index' do
    es_mock = mock
    es_mock.expects(:count).returns({'count' => 123})


    Elasticsearch::Client.expects(:new).returns(es_mock)

    assert_equal 123, Search::Index.new.count
  end
end
