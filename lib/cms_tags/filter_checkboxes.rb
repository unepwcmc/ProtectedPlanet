class FilterCheckboxes < ComfortableMexicanSofa::Content::Tag::Fragment
  def initialize(context:, params: [], source: nil)
    super
    @custom_categories = options['options'].split(',').map do |category|
      category = category.strip
    end

    @custom_categories.each do |category|
      class_eval { attr_accessor category }
      instance_variable_set "@#{category}", false
    end
  end

  def content(category)
    self.send(category)
  end
  
  def form_field(object_name, view, index)
    name = "#{object_name}[fragments_attributes][#{index}][content]"

    
    
    input =   view.content_tag(:div, class: "form-check form-check-inline") do
                @custom_categories.each do |category|
          
                  options = { 
                      id: form_field_id, 
                      class: "form-check-input"               
                  } 

                  view.concat view.hidden_field_tag(name, "#{category}: #{content(category)}", id: nil)
                  view.concat view.check_box_tag(name, "1", parse_content(category), options)
                  view.concat view.label_tag(category, nil, class: 'form-check-label pr-3')
                end
              end
            

    yield input
  end

  private

  def parse_content
    # TODO: Need to write a function to parse the content attribute of the fragment that is submitted via the form.
    false
  end

end

ComfortableMexicanSofa::Content::Renderer.register_tag(
    :filter_checkboxes, FilterCheckboxes
)
  