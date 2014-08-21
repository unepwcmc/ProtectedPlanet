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

  def self.index collection
    index = self.new collection
    index.index
  end

  def self.empty
    index = self.new
    index.empty
  end

  INDEX_NAME = Rails.application.secrets.elasticsearch["index"]

  def initialize collection=nil
    @client = Elasticsearch::Client.new(url: Rails.application.secrets.elasticsearch['url'])
    @collection = collection
  end

  def index
    @client.bulk body: documents
  end

  def empty
    @client.delete_by_query(index: INDEX_NAME, q: '*:*')
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
