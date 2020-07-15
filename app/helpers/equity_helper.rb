module EquityHelper
    def tabs
        @tabs = get_cms_tabs(2).to_json
    end
    
    # To be updated once the PA pages are actually fleshed out
    def options
        # @options = []

        @cms_page.children.first.children.published.map do |child|
            {
                title: child.label,
                text: cms_fragment_content(:text, child),
                # object[:url] = cms_fragment_content(:url, child)
                url: child.full_path    
            }          

            # if(cms_fragment_content(:image, child).try(:file) && cms_fragment_content(:image, child).file.url(:dropdownImage))
            #     object[:image] = cms_fragment_content(:image, child).file.url(:dropdownImage)
            # end

            # @options.push(object)
            
        end
    end
end