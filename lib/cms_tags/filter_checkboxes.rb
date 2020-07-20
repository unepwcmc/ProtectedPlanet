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

  def store_in_content(category)
    value = self.send(category)
    fragment.content << " #{category} #{value} "
  end
  
  def form_field(object_name, view, index)
    name = "#{object_name}[fragments_attributes][#{index}][content]"

    # Clearing the fragment's content before populating it with booleans stored
    # as strings
    fragment.content = ""

    input =   view.content_tag(:div, class: "form-check form-check-inline") do
                @custom_categories.each do |category|
          
                  options = { 
                      id: form_field_id, 
                      class: "form-check-input"               
                  } 

                  view.concat view.hidden_field_tag(name, category, id: nil)
                  store_in_content(category)
                  view.concat view.check_box_tag(name, "1", parse_content(category), options) 
                  view.concat view.label_tag(category, nil, class: 'form-check-label pr-3')
                end
              end
            
  
    yield input
  end

  private

  def parse_content(category)
    return false if fragment.content == ""

    stored_values = fragment.content.split(' ')
    
    # Making sure to grab the boolean (in string format) that follows every
    # option name in the transmogrified fragment
    ActiveModel::Type::Boolean.new.cast(stored_values[stored_values.find_index(category) + 1])
  end

end

ComfortableMexicanSofa::Content::Renderer.register_tag(
    :filter_checkboxes, FilterCheckboxes
)
  