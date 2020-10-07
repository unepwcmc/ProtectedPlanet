module Concerns::Tabs
  extend ActiveSupport::Concern
  TOTAL_TABS = 3

  included do
    include Comfy::CmsHelper
    
    def get_tabs
      tabs = []

      TOTAL_TABS.times do |i|
        tab = {
          id: i+1,
          title: cms_fragment_content(:"tab-title-#{i+1}", @cms_page)
        }

        tabs << tab
      end
      tabs
    end
  end
end