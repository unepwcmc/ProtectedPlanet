class Comfy::Cms::SearchableFragment < Comfy::Cms::Fragment
  def as_indexed_json
    self.as_json(
      only: [:id, :content]
    )
  end

  def datetime
    (attributes['datetime'] || DateTime.new(1970)).strftime('%Y-%m-%d')
  end
end
