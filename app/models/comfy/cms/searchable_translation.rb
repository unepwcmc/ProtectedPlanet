class Comfy::Cms::SearchableTranslation < Comfy::Cms::Translation
  has_many :fragments_for_index, -> { select(:id, :record_id, :content) },
    class_name: 'Comfy::Cms::SearchableFragment', foreign_key: 'record_id'

  def as_indexed_json
    self.as_json(
      only: [:id, :page_id],
      include: {
        fragments_for_index: {
          only: [:id, :content]
        }
      }
    )
  end
end
