class Search::Sorter::GeoDistance < Search::Sorter
  def to_h
    {
      "_geo_distance" => {
        @options[:field] => @term,
        "order" => "asc",
        "unit" => "km"
      }
    }
  end
end
