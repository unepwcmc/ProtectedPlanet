module Concerns::Tabs
  extend ActiveSupport::Concern
  included do
    include Comfy::CmsHelper

    def get_tabs(total_tabs, skip_tabs_with_empty_content = false)
      tabs = []
      total_tabs.times do |i|
        id = i + 1
        content_id = "tab-content-#{id}"
        content = cms_fragment_content(content_id, @cms_page)
        next if skip_tabs_with_empty_content == true && (content.nil? == true || content.empty? == true)
        tab = {
          id: id,
          title: cms_fragment_content(:"tab-title-#{i + 1}", @cms_page),
          content_id: content_id
        }

        tabs << tab
      end
      tabs
    end
  end
end
