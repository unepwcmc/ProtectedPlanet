class Search::Index
  TEMPLATE_DIRECTORY = File.join(File.dirname(__FILE__), 'templates')
  MAPPINGS_TEMPLATE = File.read(File.join(TEMPLATE_DIRECTORY, 'mappings.json'))

  INDEXES = [
    Search::CMS_INDEX,
    Search::REGION_INDEX,
    Search::COUNTRY_INDEX,
    Search::PA_INDEX
  ].freeze

  def self.create
    cms_index = init_cms_index
    cms_index.create

    pa_relation = ProtectedArea.without_geometry.includes([
                                                            { countries_for_index: :region_for_index },
                                                            :sub_locations,
                                                            :designation,
                                                            :iucn_category,
                                                            :governance
                                                          ])

    region_index = new(Search::REGION_INDEX, Region.without_geometry.all)
    region_index.create
    country_index = new(Search::COUNTRY_INDEX, Country.without_geometry.all)
    country_index.create
    pa_index = new(Search::PA_INDEX, pa_relation)
    pa_index.create

    INDEXES.each { |i| i.index }
  end

  def self.create_cms_fragments
    cms_index = init_cms_index
    cms_index.create

    cms_index.index
  end

  def self.count
    count = 0

    INDEXES.each do |index|
      count += new(index).count

    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      Rails.logger.info("#{index} not found, skipping...")
      next
    end

    count
  end

  def self.delete(indexes = INDEXES)
    indexes.each do |index_name|
      index = new index_name
      index.delete
    end
  end

  def initialize(index_name, collection = nil)
    @client = Elasticsearch::Client.new(url: Rails.application.secrets.elasticsearch[:url])
    @index_name = index_name
    @collection = collection
  end

  def create
    @client.indices.create index: @index_name, body:  mappings
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

  def self.init_cms_index
    page_relation = Comfy::Cms::SearchablePage.includes([
                                                          :fragments_for_index,
                                                          { translations_for_index: :fragments_for_index },
                                                          :categories
                                                        ])
    new(Search::CMS_INDEX, page_relation)
  end

  def documents_in_batches
    @collection.find_in_batches.each do |group|
      batch = group.each_with_object([]) do |object, bulk|
        bulk << index_header(object)
        bulk << object.as_indexed_json
      end

      yield batch
    end
  end

  def index_header _model
    { index: { _index: @index_name } }
  end

  def mappings
    @mappings ||= JSON.parse(MAPPINGS_TEMPLATE)
  end
end
