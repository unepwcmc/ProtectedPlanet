class CallToAction < ActiveRecord::Base
  self.table_name = "comfy_cms_call_to_actions"

  validates :title,
    presence: true,
    length: {maximum: 75},
    allow_nil: false
  validates :summary,
    presence: true,
    length: {maximum: 150},
    allow_nil: false
  validates :url,
    presence: true,
    length: {maximum: 255},
    allow_nil: false
end
