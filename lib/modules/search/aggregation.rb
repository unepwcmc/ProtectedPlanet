class Search::Aggregation
  TEMPLATE_DIRECTORY = File.join(File.dirname(__FILE__), 'templates')
  TEMPLATE = File.read(File.join(TEMPLATE_DIRECTORY, 'aggregations.json'))

  def self.all
    JSON.parse(TEMPLATE)
  end
end
