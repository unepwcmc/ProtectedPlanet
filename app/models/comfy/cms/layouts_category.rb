class Comfy::Cms::LayoutsCategory < ApplicationRecord
  self.table_name = 'comfy_cms_layouts_categories'
  
  belongs_to :layout
  belongs_to :layout_category
end