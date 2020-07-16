module EquityHelper
    def tabs
        @tabs = get_cms_tabs(2).to_json
    end

    def pa_pages
        @pa_pages ||= @cms_page.children.first.children
    end

    def text
        @text ||= cms_fragment_content(:text, @pa_pages.first)
    end
    
    def protected_areas
        pa_pages.published.map do |child|
            {
                title: child.label,
                text: parsed_text(text),
                url: child.full_path,
                image: include_image(cms_fragment_content(:text, child))
            }          
        end
    end
    
    def include_image(pa_page)
        # At the moment, there are no images, just a reference to a formerly 
        # existing image in the content of the fragments
        nil
    end

    def parsed_text(text)
        Nokogiri::HTML(text).css("p").last.text rescue "No description available."
    end
end