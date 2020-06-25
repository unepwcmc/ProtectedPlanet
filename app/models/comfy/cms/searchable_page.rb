class Comfy::Cms::SearchablePage < Comfy::Cms::Page
  has_many :fragments_for_index, -> { select(:id, :record_id, :content) },
    class_name: 'Comfy::Cms::SearchableFragment', foreign_key: 'record_id'

  has_many :translations_for_index, -> { select(:id, :page_id).includes(:fragments_for_index) },
    class_name: 'Comfy::Cms::SearchableTranslation', foreign_key: 'page_id'

  def as_indexed_json
    self.as_json(
      only: [:id, :label],
      include: {
        fragments_for_index: {
          only: [:id, :content]
        },
        translations_for_index: {
          only: [:id, :page_id],
          include: { fragments_for_index: { only: [:id, :content] } }
        },
        categories: { only: [:id, :label] },
        ancestors: { only: [:id, :label] }
      }
    )
  end

  def content
    fragment = self.fragments.find_by(identifier: 'content')
    return '' unless fragment
    # TODO Currently getting the first 100 characters of the string to make a summary
    fragment.content.length > 100 ? fragment.content[0..99] : fragment.content
  end

  def summary
    fragment = self.fragments.find_by(identifier: 'summary')
    return '' unless fragment

    fragment.content
  end
end
