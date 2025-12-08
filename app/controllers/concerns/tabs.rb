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

        # Check for checkbox fragments to show/hide search and map
        show_pas_search_fragment = @cms_page.fragments.find_by(identifier: "tab-show-pas-search-#{id}", tag: 'checkbox')
        show_wdpca_map_fragment = @cms_page.fragments.find_by(identifier: "tab-show-wdpca-map-#{id}", tag: 'checkbox')

        tab = {
          id: id,
          title: cms_fragment_content(:"tab-title-#{i + 1}", @cms_page),
          content_id: content_id,
          show_pas_search: show_pas_search_fragment&.boolean || false,
          show_wdpca_map: show_wdpca_map_fragment&.boolean || false
        }

        tabs << tab
      end
      tabs
    end
  end
end
