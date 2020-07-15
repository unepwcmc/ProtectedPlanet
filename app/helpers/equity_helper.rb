module EquityHelper
    # To be updated once the PA pages are actually fleshed out
    def options
        @options = []

        @cms_page.children.first.children.published.each do |child|
            object = {}

            object[:title] = child.label
            object[:text] = cms_fragment_content(:text, child)
            # object[:url] = cms_fragment_content(:url, child)
            object[:url] = child.full_path

            if(cms_fragment_content(:image, child).try(:file) && cms_fragment_content(:image, child).file.url(:dropdownImage))
                object[:image] = cms_fragment_content(:image, child).file.url(:dropdownImage)
            end

            @options.push(object)
            
        end
    end
end