class Search::Filter::Equality < Search::Filter
  def to_h
    {
      "match" => {
        @options['path'] => @term
      }
    }
  end
end
