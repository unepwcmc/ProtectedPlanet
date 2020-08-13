Rails.configuration.to_prepare do
  Comfy::Cms::Page.class_eval do
    has_many :pages_categories, foreign_key: 'page_id', dependent: :destroy
    has_many :page_categories, through: :pages_categories, foreign_key: 'page_id'

    has_many :topics, -> { joins(:layout_category).where("comfy_cms_layout_categories.label = 'topics'") },
      through: :pages_categories, class_name: 'Comfy::Cms::PageCategory', source: :page_category

    has_many :page_types, -> { joins(:layout_category).where("comfy_cms_layout_categories.label = 'types'") },
      through: :pages_categories, class_name: 'Comfy::Cms::PageCategory', source: :page_category

    accepts_nested_attributes_for :pages_categories
  end

  Comfy::Cms::Layout.class_eval do
    has_many :layouts_categories, foreign_key: 'layout_id'
    has_many :layout_categories, through: :layouts_categories, foreign_key: 'layout_id'

    accepts_nested_attributes_for :layouts_categories

    after_save :assign_layout_categories

    def assign_layout_categories
      _categories = self.content_tokens.select do |t|
        unless t.is_a?(Hash)
          false
        else
          t[:tag_class] == 'categories'
        end
      end

      delete_orphan_categories && return if _categories.blank?

      _categories.each do |cat|
        tag_name = cat[:tag_params].split(',').first
        _layout_category = Comfy::Cms::LayoutCategory.find_by(label: tag_name)
        Comfy::Cms::LayoutsCategory.find_or_create_by(
          layout_id: self.id,
          layout_category_id: _layout_category.id
        )
      end
    end

    def delete_orphan_categories
      layouts_categories = Comfy::Cms::LayoutsCategory.where(layout_id: self.id)

      self.pages.each do |page|
        layouts_categories.each do |lc|
          pcs_ids = page.page_categories.where(layout_category_id: lc.id).map(&:id)
          Comfy::Cms::PagesCategory.where(
            page_id: page.id,
            page_category_id: pcs_ids
          ).destroy_all
        end
      end

      layout_categories.destroy_all
    end
  end
end