class Comfy::Cms::PagesCategory < ApplicationRecord
  self.table_name = 'comfy_cms_pages_categories'

  belongs_to :page
  belongs_to :page_category
end