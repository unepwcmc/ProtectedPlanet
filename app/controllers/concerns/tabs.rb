module Concerns::Tabs
  extend ActiveSupport::Concern

  included do
    def get_tabs(total_tabs)
      tabs = []

      total_tabs.times do |i|
        tab = {
          id: i+1,
          title: @cms_page.fragments.where(identifier: "tab-title-#{i+1}").first.content
        }

        tabs << tab
      end
    end
  end
end