class CartoDb::Merger
  include HTTParty
  default_timeout 1800

  def initialize username, api_key
    self.class.base_uri "https://#{username}.cartodb.com/api/v2/sql"
    @options = { query: { api_key: api_key } }
  end

  def merge table_names
    @table_names = table_names


    merge_query.each do |query|
      @options[:query][:q] = query
      puts query
      puts self.class.get('/', @options)
      response = self.class.get('/', @options)
    end
  end

  private

  def merge_query
    merge_candidates.map do |table_name|
      "INSERT INTO #{@table_names[0]} (wdpaid, the_geom) SELECT wdpaid, the_geom FROM #{table_name}"
    end
  end

  def merge_candidates
    @table_names.drop(1)
  end

end
