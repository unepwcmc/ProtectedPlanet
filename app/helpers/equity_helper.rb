module EquityHelper
    def tabs
        @tabs = get_cms_tabs(2).to_json
    end
    
    def protected_areas
        @cms_page.children.first.children.published.map do |child|
            {
                title: child.label,
                text: cms_fragment_content(:text, child),
                url: child.full_path,
                image: include_image(child)
            }          
        end
    end
    
    def include_image(pa_page)
        if(cms_fragment_content(:image, pa_page).try(:file) && cms_fragment_content(:image, pa_page).file.url(:dropdownImage))
            return cms_fragment_content(:image, pa_page).file.url(:dropdownImage)
        else
            return nil
        end
    end
end