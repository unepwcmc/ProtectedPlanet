Rails.configuration.to_prepare do
  Comfy::Cms::Page.class_eval do
    has_many :pages_categories, foreign_key: 'page_id'
    has_many :page_categories, through: :pages_categories, foreign_key: 'page_id'

    has_many :topics, -> { where(group_name: 'topic') }, through: :pages_categories,
      class_name: 'Comfy::Cms::PageCategory', source: :page_category

    accepts_nested_attributes_for :pages_categories
  end
end