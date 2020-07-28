class FilterCheckboxes < ComfortableMexicanSofa::Content::Tag::Fragment
  def initialize(context:, params: [], source: nil)
    super
    @custom_categories = options['options'].split(',').map(&:strip)
  end
  
  def form_field(object_name, view, index)
    name = "#{object_name}[fragments_attributes][#{index}][content]"

    input =   view.content_tag(:div, class: "form-check form-check-inline") do
                # There should only be one content tag, so this goes outside the categories loop
                view.concat view.hidden_field_tag(name, content, id: "#{form_field_id}_content")

                @custom_categories.each do |category|
          
                  # id will be used by the custom javascript to change the content when
                  # ticking or unticking the related checkbox
                  options = {
                    id: "#{form_field_id}_#{category}",
                    class: "form-check-input"
                  }

                  # filter-checkbox name is just a dummy name which is not actually used
                  view.concat view.check_box_tag("filter-checkbox", category, parse_content(category), options) 
                  view.concat view.label_tag(name, category, class: 'form-check-label filter-checkbox pr-3')
                end
              end
            
    yield input
  end

  private

  def parse_content(category)
    return false if fragment.content.blank?
    fragment.content.split(' ').include?(category)
  end

end

ComfortableMexicanSofa::Content::Renderer.register_tag(
    :filter_checkboxes, FilterCheckboxes
)
  