class Search::Filter::Geo < Search::Filter
  def to_h
    {
      "geo_distance" => {
        "distance" => "2000km",
        @options[:field] => {
          "lat" => @term.first,
          "lon" => @term.second
        }
      }
    }
  end
end
