class Search::Filter::Geo < Search::Filter
  def to_h
    {
      "geo_distance" => {
        "distance" => "#{distance}km",
        @options['field'] => coords
      }
    }
  end

  private

  def distance
    @term[:distance_km] || 2000
  end

  def coords
    {
      "lon" => @term[:coords].first,
      "lat" => @term[:coords].second
    }
  end
end
