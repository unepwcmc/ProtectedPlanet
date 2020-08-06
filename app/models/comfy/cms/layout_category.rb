class Comfy::Cms::LayoutCategory < ApplicationRecord
  self.table_name = 'comfy_cms_layout_categories'

  has_many :page_categories
  has_many :layouts_categories
  has_many :layouts, through: :layouts_categories
end