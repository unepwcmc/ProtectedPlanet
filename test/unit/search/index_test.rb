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

  test '#index_all indexes all desired models' do
    pa_relation =  ProtectedArea.without_geometry.includes([
      {:countries_for_index => :region_for_index},
      :sub_locations,
      :designation,
      :iucn_category
    ])

    Search::Index.expects(:index).with(Country.without_geometry)
    Search::Index.expects(:index).with(Region.without_geometry)
    Search::ParallelIndexer.expects(:index).with(pa_relation)

    Search::Index.index_all
  end

  test '#drop cleans the protected areas index' do
    index_name = Rails.application.secrets.elasticsearch['index']

    es_mock = mock()
    es_mock.expects(:delete_by_query).with(index: index_name, q: '*:*')
    Elasticsearch::Client.stubs(:new).returns(es_mock)

    Search::Index.drop
  end
end
