class Search::Filter::Type < Search::Filter
  def to_h
    {
      "type" => {
        "value" => @term
      }
    }
  end
end
