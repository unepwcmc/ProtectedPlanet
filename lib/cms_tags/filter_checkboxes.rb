class FilterCheckboxes < ComfortableMexicanSofa::Content::Tag::Fragment
  def initialize(context:, params: [], source: nil)
    super
    @custom_categories = options['options'].split(',').map do |category|
      category = category.strip
    end
  end
  
  def form_field(object_name, view, index)
    name = "#{object_name}[fragments_attributes][#{index}][content]"

    
    
    input =   view.content_tag(:div, class: "form-check form-check-inline") do
                @custom_categories.each do |category|
          
                  options = { 
                      id: form_field_id, 
                      class: "form-check-input"               
                  } 

                  view.concat view.hidden_field_tag(name, "0", id: nil)
                  view.concat view.check_box_tag(name, "1", false, options)
                  view.concat view.label_tag(category, nil, class: 'form-check-label pr-3')
                end
              end
            

    yield input
  end

end

ComfortableMexicanSofa::Content::Renderer.register_tag(
    :filter_checkboxes, FilterCheckboxes
)
  