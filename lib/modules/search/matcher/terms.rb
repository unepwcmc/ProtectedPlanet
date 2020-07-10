class Search::Matcher::Terms < Search::Matcher
  def to_h
    if @term.blank?
      ids = []
    else
      ids = @term.split(',').map(&:strip).map(&:to_i)
      ids = [] if ids.include?(0)
    end

    {"terms" => {@options[:path] => ids}}
  end
end
