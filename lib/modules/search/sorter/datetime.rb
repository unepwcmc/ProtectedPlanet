class Search::Sorter::Datetime < Search::Sorter
  def to_h
    {
      @term => {
        "order" => "desc"
      }
    }
  end
end