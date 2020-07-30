class Comfy::Cms::PageCategory < ApplicationRecord
  self.table_name = 'comfy_cms_page_categories'

  belongs_to :layout_category
  has_many :pages_categories
  has_many :pages, through: :pages_categories
end