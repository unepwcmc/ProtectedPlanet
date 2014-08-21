require 'test_helper'

class IndexerTest < ActiveSupport::TestCase
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
    Search::Index.expects(:index).with(Country.without_geometry)
    Search::Index.expects(:index).with(Region.without_geometry)
    Search::Index.expects(:index).with(ProtectedArea.without_geometry)

    Search::Index.index_all
  end
end
