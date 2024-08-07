class Comfy::Cms::SearchablePage < Comfy::Cms::Page
  has_many :fragments_for_index, -> { select(:id, :record_id, :content, :datetime) },
    class_name: 'Comfy::Cms::SearchableFragment', foreign_key: 'record_id'

  has_many :translations_for_index, -> { select(:id, :page_id).includes(:fragments_for_index) },
    class_name: 'Comfy::Cms::SearchableTranslation', foreign_key: 'page_id'

  def as_indexed_json
    # index only published pages
    return unless is_published
    self.as_json(
      only: [:id, :label],
      methods: [:published_date],
      include: {
        fragments_for_index: {
          only: [:id, :content]
        },
        translations_for_index: {
          only: [:id, :page_id],
          include: { fragments_for_index: { only: [:id, :content] } }
        },
        categories: { only: [:id, :label] },
        topics: { only: [:id, :label] },
        page_types: { only: [:id, :label] },
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

  # TODO Consider lazy loading
  def image
    fragment = self.fragments.find_by(identifier: 'image')
    return '' unless fragment && fragment.attachments_blobs.first

    if Rails.env.development?
      Rails.application.routes.url_helpers.rails_blob_path(fragment.attachments_blobs.first)
    else
      fragment.attachments_blobs.first.service_url&.split('?')&.first
    end
  end

  def published_date
    fragment = self.fragments_for_index.find_by(identifier: 'published_date')
    fragment ? fragment.datetime : ''
  end
end
