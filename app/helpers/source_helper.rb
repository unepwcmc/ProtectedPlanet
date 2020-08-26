module SourceHelper
  def convert_into_hash(sources)
    sources.to_a.map do |source|
      {
        title: source['title'],
        # sources which have no data for `date_updated` are currently set to '-' 
        date_updated: source['year'] ? source['year'].round : '-',
        resp_party: source['responsible_party']
      }
    end
  end
end