class Search::Index
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

    index = 1;
    total = @model_enumerable.first.class.count

    @model_enumerable.find_in_batches.each do |group|
      group.each do |model_instance|
        STDOUT.write "\r#{index}/#{total}";
        documents << index_header(model_instance)
        documents << model_instance.as_indexed_json
        index += 1
      end
    end
    puts

    documents
  end

  def index_header model
    {index: {_index: INDEX_NAME, _type: model.class.to_s.underscore}}
  end
end
