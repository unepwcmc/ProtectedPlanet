class Search::Index
  TEMPLATE_DIRECTORY = File.join(File.dirname(__FILE__), 'templates')
  MAPPINGS_TEMPLATE = File.read(File.join(TEMPLATE_DIRECTORY, 'mappings.json'))

  def self.create
    pa_relation = ProtectedArea.without_geometry.includes([
      {:countries_for_index => :region_for_index},
      :sub_locations,
      :designation,
      :iucn_category,
      :governance
    ])
    Search::Index.index Search::COUNTRY_INDEX, Country.without_geometry.all
    Search::Index.index Search::PA_INDEX, pa_relation
  end

  def self.index index_name, collection
    index = self.new index_name, collection
    index.index
  end

  def self.count index_name = nil
    if index_name.nil?
      self.new(Search::COUNTRY_INDEX).count + self.new(Search::PA_INDEX).count
    else
      index = self.new index_name
      index.count
    end
  end

  def self.delete index_name
    index = self.new index_name
    index.delete
  end


  def initialize index_name, collection=nil
    @client = Elasticsearch::Client.new(url: Rails.application.secrets.elasticsearch['url'])
    @client.indices.create index: index_name, body:  mappings 
    @index_name = index_name
    @collection = collection
  end

  def index
    documents_in_batches { |batch| @client.bulk body: batch }
  end

  def delete
    @client.indices.delete index: @index_name
    
  rescue Elasticsearch::Transport::Transport::Errors::NotFound
    Rails.logger.warn("Index #{@index_name} not found. Skipping")
  end

  def count 
    @client.count(index: @index_name)['count']
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
    {index: {_index: @index_name}}
  end

  def mappings
    @mappings ||= JSON.parse(MAPPINGS_TEMPLATE)
  end
end
