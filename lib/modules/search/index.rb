class Search::Index
  def self.index_all
    [Country, Region, ProtectedArea].each do |model|
      Search::Index.index model.without_geometry
    end
  end

  def self.index model_enumerable
    index = self.new model_enumerable
    index.index
  end

  INDEX_NAME = Rails.application.secrets.elasticsearch["index"]

  def initialize model_enumerable
    @client = Elasticsearch::Client.new
    @model_enumerable = model_enumerable
  end

  def index
    @client.bulk body: documents
  end

  private

  def documents
    documents = []

    @model_enumerable.find_in_batches.each do |group|
      group.each do |model_instance|
        documents << index_header(model_instance)
        documents << model_instance.as_indexed_json
      end
    end

    documents
  end

  def index_header model
    {index: {_index: INDEX_NAME, _type: model.class.to_s.underscore}}
  end
end
