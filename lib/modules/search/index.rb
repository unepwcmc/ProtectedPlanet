class Search::Index
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
