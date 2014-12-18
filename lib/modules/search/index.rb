class Search::Index
  TEMPLATE_DIRECTORY = File.join(File.dirname(__FILE__), 'templates')
  MAPPINGS_TEMPLATE = File.read(File.join(TEMPLATE_DIRECTORY, 'mappings.json'))

  def self.create
    pa_relation = ProtectedArea.without_geometry.includes([
      {:countries_for_index => :region_for_index},
      :sub_locations,
      :designation,
      :iucn_category
    ])

    Search::Index.index Country.without_geometry.all
    Search::Index.index Region.without_geometry.all

    Search::Index.create_mapping 'protected_area'
    Search::Index.index pa_relation
  end

  def self.index collection
    index = self.new collection
    index.index
  end

  def self.count
    index = self.new
    index.count
  end

  def self.create_mapping collection
    index = self.new
    index.create_mapping collection
  end

  def self.delete
    index = self.new
    index.delete
  end

  INDEX_NAME = Rails.application.secrets.elasticsearch["index"]

  def initialize collection=nil
    @client = Elasticsearch::Client.new(url: Rails.application.secrets.elasticsearch['url'])
    @collection = collection
  end

  def index
    documents_in_batches { |batch| @client.bulk body: batch }
  end

  def delete
    @client.indices.delete index: INDEX_NAME
  end

  def count
    @client.count['count']
  end

  def create_mapping type
    raise ArgumentError, "No mapping found for type #{type}" unless mappings[type]
    @client.indices.put_mapping(
      index: INDEX_NAME,
      type: type,
      body: { type => mappings[type] }
    )
  end

  private

  def documents_in_batches
    @collection.find_in_batches.each do |group|
      batch = group.each_with_object([]) do |object, bulk|
        bulk << index_header(object)
        bulk << object.as_indexed_json
      end

      yield batch
    end
  end

  def index_header model
    {index: {_index: INDEX_NAME, _type: model.class.to_s.underscore}}
  end

  def mappings
    @mappings ||= JSON.parse(MAPPINGS_TEMPLATE)
  end
end
