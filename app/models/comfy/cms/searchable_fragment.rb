class Comfy::Cms::SearchableFragment < Comfy::Cms::Fragment
  def as_indexed_json
    self.as_json(
      only: [:id, :content]
    )
  end
end
