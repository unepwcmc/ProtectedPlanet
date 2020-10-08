module Concerns::Tabs
  extend ActiveSupport::Concern
  included do
    include Comfy::CmsHelper
    
    def get_tabs total_tabs
      tabs = []

      total_tabs.times do |i|
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