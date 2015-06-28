class Search::Filter::Equality < Search::Filter
  def to_h
    {
      "term" => {
        @options['path'] => @term
      }
    }
  end
end
