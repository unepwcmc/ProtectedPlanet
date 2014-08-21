class Search::Index
  def self.index_all
    pa_relation = ProtectedArea.without_geometry.includes([
      {:countries_for_index => :region_for_index},
      :sub_locations,
      :designation,
      :iucn_category
    ])

    Search::Index.index Country.without_geometry.all
    Search::Index.index Region.without_geometry.all
    Search::ParallelIndexer.index pa_relation
  end

  def self.drop
    Elasticsearch::Client.new.delete_by_query(index: INDEX_NAME, q: '*:*')
  end

  def self.index collection
    index = self.new collection
    index.index
  end

  INDEX_NAME = Rails.application.secrets.elasticsearch["index"]

  def initialize collection
    @client = Elasticsearch::Client.new
    @collection = collection
  end

  def index
    @client.bulk body: documents
  end

  private

  def documents
    documents = []

    @collection.each do |object|
      documents << index_header(object)
      documents << object.as_indexed_json
    end

    documents
  end

  def index_header model
    {index: {_index: INDEX_NAME, _type: model.class.to_s.underscore}}
  end
end
